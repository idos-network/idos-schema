-- PRIVILEGE SETTINGS

REVOKE IF GRANTED SELECT ON main FROM default;


-- EXTENSION INITIALIZATION

USE IF NOT EXISTS idos AS idos;


-- TABLES

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    recipient_encryption_public_key TEXT NOT NULL,
    inserter TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    address TEXT NOT NULL,
    public_key TEXT,
    wallet_type TEXT NOT NULL,
    message TEXT,
    signature TEXT,
    inserter TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS wallets_evm_scan ON wallets(wallet_type, address);
CREATE INDEX IF NOT EXISTS wallets_near_scan ON wallets(wallet_type, public_key);

CREATE TABLE IF NOT EXISTS credentials (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    verifiable_credential_id TEXT,
    public_notes TEXT NOT NULL,
    content TEXT NOT NULL,
    encryptor_public_key TEXT NOT NULL,
    issuer_auth_public_key TEXT NOT NULL,
    inserter TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS credentials_user_id ON credentials(user_id);
CREATE INDEX IF NOT EXISTS credentials_vc_id ON credentials(verifiable_credential_id);

CREATE TABLE IF NOT EXISTS shared_credentials (
    original_id UUID NOT NULL,
    copy_id UUID NOT NULL,
    PRIMARY KEY (original_id, copy_id),
    FOREIGN KEY (original_id) REFERENCES credentials(id) ON DELETE CASCADE,
    FOREIGN KEY (copy_id) REFERENCES credentials(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS shared_credentials_copy_id ON shared_credentials(copy_id);

CREATE TABLE IF NOT EXISTS user_attributes (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    attribute_key TEXT NOT NULL,
    value TEXT NOT NULL,
    inserter TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS user_attributes_user_id ON user_attributes(user_id);

CREATE TABLE IF NOT EXISTS shared_user_attributes (
    original_id UUID NOT NULL,
    copy_id UUID NOT NULL,
    PRIMARY KEY (original_id, copy_id),
    FOREIGN KEY (original_id) REFERENCES user_attributes(id) ON DELETE CASCADE,
    FOREIGN KEY (copy_id) REFERENCES user_attributes(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS shared_user_attributes_copy_id ON shared_user_attributes(copy_id);

CREATE TABLE IF NOT EXISTS inserters (
    id UUID PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS delegates (
    address TEXT PRIMARY KEY,
    inserter_id UUID NOT NULL,
    FOREIGN KEY (inserter_id) REFERENCES inserters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consumed_write_grants (
    id UUID PRIMARY KEY,
    owner_wallet_identifier TEXT NOT NULL, -- user wallet/pk
    grantee_wallet_identifier TEXT NOT NULL, -- grantee wallet/pk
    issuer_public_key TEXT NOT NULL,
    original_credential_id UUID,
    copy_credential_id UUID,
    access_grant_timelock TEXT,
    not_usable_before TEXT,
    not_usable_after TEXT,
    FOREIGN KEY (original_credential_id) REFERENCES credentials(id) ON DELETE SET NULL,
    FOREIGN KEY (copy_credential_id) REFERENCES credentials(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS consumed_insert_grants (
    id UUID PRIMARY KEY,
    owner_wallet_identifier TEXT NOT NULL, -- user wallet/pk
    issuer_public_key TEXT NOT NULL,
    credential_id UUID,
    not_usable_before TEXT,
    not_usable_after TEXT,
    FOREIGN KEY (credential_id) REFERENCES credentials(id) ON DELETE SET NULL,
);

CREATE TABLE IF NOT EXISTS access_grants (
    id UUID PRIMARY KEY,
    ag_owner_user_id UUID NOT NULL,
    ag_grantee_wallet_identifier TEXT NOT NULL,
    data_id UUID NOT NULL,
    locked_until INT8 NOT NULL DEFAULT 0,
    content_hash TEXT,
    height int NOT NULL,
    inserter_type TEXT NOT NULL,
    inserter_id TEXT NOT NULL,
    FOREIGN KEY (ag_owner_user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ag_data_id ON access_grants(data_id);
CREATE INDEX IF NOT EXISTS ag_grantee_content_hash ON access_grants(ag_grantee_wallet_identifier, content_hash);
CREATE INDEX IF NOT EXISTS ag_owner_user_id ON access_grants(ag_owner_user_id);


-- INSERTER AND DELEGATE ACTIONS

CREATE OR REPLACE ACTION add_inserter_as_owner($id UUID, $name TEXT) OWNER PUBLIC {
    INSERT INTO inserters (id, name) VALUES ($id, $name);
};

CREATE OR REPLACE ACTION delete_inserter_as_owner($id UUID) OWNER PUBLIC {
    DELETE FROM inserters WHERE id = $id;
};

CREATE OR REPLACE ACTION add_delegate_as_owner($address TEXT, $inserter_id UUID) OWNER PUBLIC {
  INSERT INTO delegates (address, inserter_id) VALUES ($address, $inserter_id);
};

CREATE OR REPLACE ACTION delete_delegate_as_owner($address TEXT) OWNER PUBLIC {
  DELETE FROM delegates WHERE address=$address;
};

CREATE OR REPLACE ACTION get_inserter() PRIVATE VIEW RETURNS (name TEXT) {
    for $row in SELECT inserters.name FROM inserters INNER JOIN delegates ON inserters.id = delegates.inserter_id WHERE delegates.address = @caller {
        return $row.name;
    }
    error('Unauthorized inserter');
};

CREATE OR REPLACE ACTION get_inserter_or_null() PRIVATE VIEW RETURNS (name TEXT) {
    for $row in SELECT inserters.name FROM inserters INNER JOIN delegates ON inserters.id = delegates.inserter_id WHERE delegates.address = @caller {
        return $row.name;
    }
    return null;
};


-- USER ACTIONS

CREATE OR REPLACE ACTION add_user_as_inserter($id UUID, $recipient_encryption_public_key TEXT) PUBLIC {
    $inserter := get_inserter();
    INSERT INTO users (id, recipient_encryption_public_key, inserter) VALUES ($id, $recipient_encryption_public_key, $inserter);
};

CREATE OR REPLACE ACTION update_user_pub_key_as_inserter($id UUID, $recipient_encryption_public_key TEXT) PUBLIC {
    get_inserter();
    UPDATE users SET recipient_encryption_public_key=$recipient_encryption_public_key
        WHERE id = $id;
};

CREATE OR REPLACE ACTION get_user() PUBLIC VIEW RETURNS (id UUID, recipient_encryption_public_key TEXT) {
    for $row in SELECT id, recipient_encryption_public_key FROM users
        WHERE id = (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller)) {
        return $row.id, $row.recipient_encryption_public_key;
    }
};

CREATE OR REPLACE ACTION get_user_as_inserter($id UUID) PUBLIC VIEW RETURNS (id UUID, recipient_encryption_public_key TEXT, inserter TEXT) {
    get_inserter();
    for $row in SELECT * FROM users WHERE id = $id {
        return $row.id, $row.recipient_encryption_public_key, $row.inserter;
    }
};


-- WALLET ACTIONS

CREATE OR REPLACE ACTION upsert_wallet_as_inserter(
    $id UUID,
    $user_id UUID,
    $address TEXT,
    $public_key TEXT,
    $wallet_type TEXT,
    $message TEXT,
    $signature TEXT
) PUBLIC {
    if $wallet_type = 'NEAR' {
        if $public_key is null {
            error('NEAR wallets require a public_key to be given');
        }

        if !idos.is_valid_public_key($public_key, $wallet_type) {
            error('invalid or unsupported public key');
        }
    }

    for $row_evm in SELECT 1 FROM wallets WHERE $wallet_type = 'EVM' AND id != $id AND address = $address COLLATE NOCASE {
        error('this EVM wallet address already exists in idos');
    }

    for $row_near in SELECT 1 FROM wallets WHERE $wallet_type = 'NEAR' AND id != $id AND public_key = $public_key COLLATE NOCASE {
        error('this NEAR wallet public key already exists in idos');
    }

    $inserter := get_inserter();
    INSERT INTO wallets (id, user_id, address, public_key, wallet_type, message, signature, inserter)
    VALUES ($id, $user_id, $address, $public_key, $wallet_type, $message, $signature, $inserter)
    ON CONFLICT(id) DO UPDATE
    SET user_id=$user_id, address=$address, public_key=$public_key, wallet_type=$wallet_type, message=$message, signature=$signature, inserter=$inserter;
};

CREATE OR REPLACE ACTION add_wallet($id UUID, $address TEXT, $public_key TEXT, $message TEXT, $signature TEXT) PUBLIC {
    $wallet_type := idos.determine_wallet_type($address);

    if $wallet_type = 'NEAR' AND $public_key is null {
        error('NEAR wallets require a public_key to be given');
    }

    if $wallet_type = 'NEAR' {
        if !idos.is_valid_public_key($public_key, $wallet_type) {
            error('invalid or unsupported public key');
        }
    }

    for $row in SELECT 1 FROM wallets WHERE $wallet_type = 'EVM' AND address = $address COLLATE NOCASE {
        error('this EVM wallet address already exists in idos');
    }
    for $row in SELECT 1 FROM wallets WHERE $wallet_type = 'NEAR' AND public_key = $public_key COLLATE NOCASE {
        error('this NEAR wallet public key already exists in idos');
    }

    INSERT INTO wallets (id, user_id, address, public_key, wallet_type, message, signature)
    VALUES (
        $id,
        (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller)
        ),
        $address,
        CASE
            WHEN $public_key = '' THEN NULL
            ELSE $public_key
        END,
        $wallet_type,
        $message,
        $signature
    );
};

CREATE OR REPLACE ACTION get_wallets() PUBLIC VIEW RETURNS table (
    id UUID,
    user_id UUID,
    address TEXT,
    public_key TEXT,
    wallet_type TEXT,
    message TEXT,
    signature TEXT,
    inserter TEXT
) {
    return SELECT DISTINCT w1.id, w1.user_id, w1.address, w1.public_key, w1.wallet_type, w1.message, w1.signature, w1.inserter
        FROM wallets AS w1
        INNER JOIN wallets AS w2 ON w1.user_id = w2.user_id
        WHERE (
            w2.wallet_type = 'EVM' AND w2.address = @caller COLLATE NOCASE
        ) OR (
            w2.wallet_type = 'NEAR' AND w2.public_key = @caller
        );
};

CREATE OR REPLACE ACTION remove_wallet($id UUID) PUBLIC {
    for $row in SELECT id FROM wallets
        WHERE id = $id
        AND ((wallet_type = 'EVM' AND address=@caller COLLATE NOCASE) OR (wallet_type = 'NEAR' AND public_key = @caller))
        AND EXISTS (
            SELECT count(id) FROM wallets
                WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE) OR (wallet_type = 'NEAR' AND public_key = @caller)
                GROUP BY user_id HAVING count(id) = 1
        ) {
        error('You can not delete a wallet you are connected with. To delete this wallet you have to connect other wallet.');
    }

    DELETE FROM wallets
    WHERE id=$id AND user_id=(SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
        OR (wallet_type = 'NEAR' AND public_key = @caller)
    );
};


-- CREDENTIAL ACTIONS

CREATE OR REPLACE ACTION upsert_credential_as_inserter (
    $id UUID,
    $user_id UUID,
    $issuer_auth_public_key TEXT,
    $encryptor_public_key TEXT,
    $content TEXT,
    $public_notes TEXT,
    $public_notes_signature TEXT,
    $broader_signature TEXT
) PUBLIC {
    $inserter := get_inserter(); -- throw an error if not authorized

    $result = idos.assert_credential_signatures($issuer_auth_public_key, $public_notes, $public_notes_signature, $content, $broader_signature);
    if !$result {
        error('signature is wrong');
    }

    $verifiable_credential_id = idos.get_verifiable_credential_id($public_notes);

    INSERT INTO credentials (id, user_id, verifiable_credential_id, public_notes, content, encryptor_public_key, issuer_auth_public_key, inserter)
    VALUES (
        $id,
        $user_id,
        CASE WHEN $verifiable_credential_id = '' THEN NULL ELSE $verifiable_credential_id END,
        $public_notes,
        $content,
        $encryptor_public_key,
        $issuer_auth_public_key,
        $inserter
    )
    ON CONFLICT(id) DO UPDATE
    SET user_id=$user_id,
        verifiable_credential_id=(CASE WHEN $verifiable_credential_id = '' THEN NULL ELSE $verifiable_credential_id END),
        public_notes=$public_notes,
        content=$content,
        encryptor_public_key=$encryptor_public_key,
        issuer_auth_public_key=$issuer_auth_public_key,
        inserter=$inserter;
};

CREATE OR REPLACE ACTION add_credential (
    $id UUID,
    $issuer_auth_public_key TEXT,
    $encryptor_public_key TEXT,
    $content TEXT,
    $public_notes TEXT,
    $public_notes_signature TEXT,
    $broader_signature TEXT
) PUBLIC {
    $result = idos.assert_credential_signatures($issuer_auth_public_key, $public_notes, $public_notes_signature, $content, $broader_signature);
    if !$result {
        error('signature is wrong');
    }

    $verifiable_credential_id = idos.get_verifiable_credential_id($public_notes);

    INSERT INTO credentials (id, user_id, verifiable_credential_id, public_notes, content, encryptor_public_key, issuer_auth_public_key)
    VALUES (
        $id,
        (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller)
        ),
        CASE WHEN $verifiable_credential_id = '' THEN NULL ELSE $verifiable_credential_id END,
        $public_notes,
        $content,
        $encryptor_public_key,
        $issuer_auth_public_key
    );
};

CREATE OR REPLACE ACTION insert_credential_by_dig(
    $id UUID,
    $content TEXT,
    $public_notes TEXT,
    $public_notes_signature TEXT,
    $issuer_auth_public_key TEXT,
    $encryptor_public_key TEXT,
    $dig_owner TEXT,
    $dig_id UUID,
    $dig_not_before TEXT,
    $dig_not_after TEXT,
    $dig_signature TEXT) PUBLIC {

    $dig_owner_found bool := false;
    for $row1 in SELECT 1 FROM wallets WHERE (wallet_type = 'EVM' AND address=$dig_owner COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = $dig_owner) {
        $dig_owner_found := true;
        break;
    }
    if !$dig_owner_found {
        error('dig_owner not found');
    }

    -- Check the format and precedence
    -- Will fail if times are not in the RFC3339 format
    if !idos.validate_not_usable_times($dig_not_before, $dig_not_after) {
        error('dig_not_before must be before dig_not_after');
    }

    -- Check if current block timestamp in time range allowed by an insert grant.
    -- @block_timestamp is a timestamp of previous block, which is can be a few seconds earlier
    -- (max is 6 seconds in current network consensus settings) then a time on a requester's machine.
    -- Also, if requester's machine has wrong time, it can be an issue.
    if parse_unix_timestamp($dig_not_before, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')::int > (@block_timestamp + 6)
            OR @block_timestamp > parse_unix_timestamp($dig_not_after, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')::int {

        error('this insert grant can only be used after dig_not_before and before dig_not_after');
    }

    $dig_result = idos.dig_verify_owner(
        $dig_owner,
        $issuer_auth_public_key,
        $dig_id::TEXT,
        $dig_not_before,
        $dig_not_after,
        $dig_signature
    );
    if !$dig_result {
        error('verify owner failed');
    }

    $cred_result = idos.assert_credential_signatures(
        $issuer_auth_public_key,
        $public_notes,
        $public_notes_signature,
        $content,
        $broader_signature
    );
    if !$cred_result {
        error('credential signature is wrong');
    }

    $verifiable_credential_id = idos.get_verifiable_credential_id($public_notes);

    -- TODO: change to a new public_notes approach when merge public_notes PR
    INSERT INTO credentials (id, user_id, verifiable_credential_id, public_notes, content, encryptor_public_key, issuer_auth_public_key, inserter)
    VALUES (
        $id,
        (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=$dig_owner COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = $dig_owner)),
        CASE WHEN $verifiable_credential_id = '' THEN NULL ELSE $verifiable_credential_id END,
        $public_notes,
        $content,
        $encryptor_public_key,
        $issuer_auth_public_key,
        $dig_id::TEXT
    );

    INSERT INTO consumed_insert_grants (
        id,
        owner_wallet_identifier,
        issuer_public_key,
        credential_id,
        not_usable_before,
        not_usable_after
    ) VALUES (
        $dig_id,
        $dig_owner,
        $issuer_auth_public_key,
        $id,
        $dig_not_before,
        $dig_not_after
    );
};

CREATE OR REPLACE ACTION get_credentials() PUBLIC VIEW RETURNS table (
    id UUID,
    user_id UUID,
    public_notes TEXT,
    issuer_auth_public_key TEXT,
    inserter TEXT,
    original_id UUID
) {
    return SELECT DISTINCT c.id, c.user_id, c.public_notes, c.issuer_auth_public_key, c.inserter, sc.original_id
        FROM credentials AS c
        LEFT JOIN shared_credentials AS sc ON c.id = sc.copy_id
        INNER JOIN wallets ON c.user_id = wallets.user_id
        WHERE (
            wallets.wallet_type = 'EVM' AND wallets.address = @caller COLLATE NOCASE
        ) OR (
            wallets.wallet_type = 'NEAR' AND wallets.public_key = @caller
        );
};

CREATE OR REPLACE ACTION get_credentials_shared_by_user($user_id UUID, $issuer_auth_public_key TEXT) PUBLIC VIEW RETURNS table (
    id UUID,
    user_id UUID,
    public_notes TEXT,
    encryptor_public_key TEXT,
    issuer_auth_public_key TEXT,
    inserter TEXT,
    original_id UUID) {
    if $issuer_auth_public_key is null {
      return SELECT DISTINCT c.id, c.user_id, oc.public_notes, c.encryptor_public_key, c.issuer_auth_public_key, c.inserter, sc.original_id AS original_id
          FROM credentials AS c
          INNER JOIN access_grants as ag ON c.id = ag.data_id
          INNER JOIN shared_credentials AS sc ON c.id = sc.copy_id
          INNER JOIN credentials as oc ON oc.id = sc.original_id
          WHERE c.user_id = $user_id
              AND ag.ag_grantee_wallet_identifier = @caller COLLATE NOCASE;
    } else {
        return SELECT DISTINCT c.id, c.user_id, oc.public_notes, c.encryptor_public_key, c.issuer_auth_public_key, c.inserter, sc.original_id AS original_id
          FROM credentials AS c
          INNER JOIN access_grants as ag ON c.id = ag.data_id
          INNER JOIN shared_credentials AS sc ON c.id = sc.copy_id
          INNER JOIN credentials as oc ON oc.id = sc.original_id
          WHERE c.user_id = $user_id
            AND c.issuer_auth_public_key = $issuer_auth_public_key
            AND ag.ag_grantee_wallet_identifier = @caller COLLATE NOCASE;
    }
};

CREATE OR REPLACE ACTION edit_credential (
    $id UUID,
    $public_notes TEXT,
    $public_notes_signature TEXT,
    $broader_signature TEXT,
    $content TEXT,
    $encryptor_public_key TEXT,
    $issuer_auth_public_key TEXT
) PUBLIC {
    for $row in SELECT 1 from credentials AS c
                    INNER JOIN shared_credentials AS sc on c.id = sc.copy_id
                    WHERE c.id = $id
                    AND c.user_id=(SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
                        OR (wallet_type = 'NEAR' AND public_key = @caller)) {
        error('Can not edit shared credential');
    }

    $result = idos.assert_credential_signatures($issuer_auth_public_key, $public_notes, $public_notes_signature, $content, $broader_signature);
    if !$result {
        error('signature is wrong');
    }

    $verifiable_credential_id = idos.get_verifiable_credential_id($public_notes);

    UPDATE credentials
    SET public_notes=$public_notes,
        verifiable_credential_id = (CASE WHEN $verifiable_credential_id = '' THEN NULL ELSE $verifiable_credential_id END),
        content=$content,
        encryptor_public_key=$encryptor_public_key,
        issuer_auth_public_key=$issuer_auth_public_key
    WHERE id=$id
    AND user_id=(SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
        OR (wallet_type = 'NEAR' AND public_key = @caller)
    );
};

-- Be aware that @caller here is ed25519 public key, hex encoded.
-- All other @caller in the schema are either secp256k1 or nep413
-- This action can't be called by kwil-cli (as kwil-cli uses secp256k1 only)
CREATE OR REPLACE ACTION edit_public_notes_as_issuer($public_notes_id TEXT, $public_notes TEXT) PUBLIC {
    UPDATE credentials SET public_notes = $public_notes
    WHERE issuer_auth_public_key = @caller
        AND verifiable_credential_id = $public_notes_id;
};

CREATE OR REPLACE ACTION remove_credential($id UUID) PUBLIC {
    if !credential_belongs_to_caller($id) {
        error('the credential does not belong to the caller');
    }

    if has_locked_access_grants($id) {
        error('there are locked access grants for this credential');
    }
    DELETE FROM credentials
    WHERE id=$id
    AND user_id=(SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
        OR (wallet_type = 'NEAR' AND public_key = @caller)
    );

    DELETE FROM access_grants WHERE data_id = $id;
};

CREATE OR REPLACE ACTION share_credential (
    $id UUID,
    $original_credential_id UUID,
    $public_notes TEXT,
    $public_notes_signature TEXT,
    $broader_signature TEXT,
    $content TEXT,
    $encryptor_public_key TEXT,
    $issuer_auth_public_key TEXT,
    $grantee_wallet_identifier TEXT,
    $locked_until INT8
) PUBLIC {
    if !credential_belongs_to_caller($original_credential_id) {
        error('original credential does not belong to the caller');
    }

    if $public_notes != '' {
        error('shared credentials cannot have public_notes, it must be an empty string');
    }

    add_credential(
        $id,
        $issuer_auth_public_key,
        $encryptor_public_key,
        $content,
        $public_notes,
        $public_notes_signature,
        $broader_signature
    );
    INSERT INTO shared_credentials (original_id, copy_id) VALUES ($original_credential_id, $id);

    create_access_grant(
        $grantee_wallet_identifier,
        $id,
        $locked_until::int,
        null,
        'user',
        @caller
    );
};

-- Passporting scenario
CREATE OR REPLACE ACTION create_credential_copy(
    $id UUID,
    $original_credential_id UUID,
    $public_notes TEXT,
    $public_notes_signature TEXT,
    $broader_signature TEXT,
    $content TEXT,
    $encryptor_public_key TEXT,
    $issuer_auth_public_key TEXT
) PUBLIC {
    if !credential_belongs_to_caller($original_credential_id) {
        error('original credential does not belong to the caller');
    }

    if $public_notes != '' {
        error('shared credentials cannot have public_notes, it must be an empty string');
    }

    add_credential(
        $id,
        $issuer_auth_public_key,
        $encryptor_public_key,
        $content,
        $public_notes,
        $public_notes_signature,
        $broader_signature
    );
    INSERT INTO shared_credentials (original_id, copy_id) VALUES ($original_credential_id, $id);
};

-- It can be used with EVM-compatible signatures only
CREATE OR REPLACE ACTION share_credential_through_dag (
    $id UUID,
    $user_id UUID,
    $issuer_auth_public_key TEXT,
    $encryptor_public_key TEXT,
    $content TEXT,
    $public_notes TEXT,
    $public_notes_signature TEXT,
    $broader_signature TEXT,
    $original_credential_id UUID,
    $dag_owner_wallet_identifier TEXT,
    $dag_grantee_wallet_identifier TEXT,
    $dag_locked_until INT8,
    $dag_signature TEXT
) PUBLIC {
    $orig_cred_belongs_user bool := false;
    for $row1 in SELECT 1 from credentials WHERE id = $original_credential_id AND user_id = $user_id {
        $orig_cred_belongs_user := true;
    }
    if !$orig_cred_belongs_user {
        error('the original credential does not belong to the user');
    }

    -- This works for EVM-compatible signatures only
    $owner_verified = idos.verify_owner_without_hash(
        $dag_owner_wallet_identifier,
        $dag_grantee_wallet_identifier,
        $id::TEXT,
        $dag_locked_until,
        $dag_signature
    );
    if !$owner_verified {
        error('the signature was signed not by the dag_owner');
    }

    if $public_notes != '' {
        error('shared credentials cannot have public_notes, it must be an empty string');
    }

    $result = idos.assert_credential_signatures($issuer_auth_public_key, $public_notes, $public_notes_signature, $content, $broader_signature);
    if !$result {
        error('credential public_notes_signature or broader_signature is wrong');
    }

    $dag_signed_by_user bool := false;
    for $row2 in SELECT 1 from wallets
            WHERE wallet_type = 'EVM'
            AND address = $dag_owner_wallet_identifier COLLATE NOCASE
            AND user_id = $user_id {
        $dag_signed_by_user := true;
        break;
    }
    if !$dag_signed_by_user {
        error('the DAG is not signed by the user');
    }

    $verifiable_credential_id = idos.get_verifiable_credential_id($public_notes);

    $inserter := get_inserter_or_null();
    INSERT INTO credentials (id, user_id, verifiable_credential_id, public_notes, content, encryptor_public_key, issuer_auth_public_key, inserter)
    VALUES (
        $id,
        $user_id,
        CASE WHEN $verifiable_credential_id = '' THEN NULL ELSE $verifiable_credential_id END,
        $public_notes,
        $content,
        $encryptor_public_key,
        $issuer_auth_public_key,
        $inserter
    );

    INSERT INTO shared_credentials (original_id, copy_id) VALUES ($original_credential_id, $id);

    create_access_grant(
        $dag_grantee_wallet_identifier,
        $id,
        $dag_locked_until::int,
        null,
        'dag_message',
        @caller
    );
};

CREATE OR REPLACE ACTION create_credentials_by_dwg(
    $issuer_auth_public_key TEXT,
    $original_encryptor_public_key TEXT,
    $original_credential_id UUID,
    $original_content TEXT,
    $original_public_notes TEXT,
    $original_public_notes_signature TEXT,
    $original_broader_signature TEXT,
    $copy_encryptor_public_key TEXT,
    $copy_credential_id UUID,
    $copy_content TEXT,
    $copy_public_notes_signature TEXT,
    $copy_broader_signature TEXT,
    $content_hash TEXT, -- For access grant
    $dwg_owner TEXT,
    $dwg_grantee TEXT,
    $dwg_issuer_public_key TEXT,
    $dwg_id UUID,
    $dwg_access_grant_timelock TEXT,
    $dwg_not_before TEXT,
    $dwg_not_after TEXT,
    $dwg_signature TEXT) PUBLIC {

    -- Check the content creator (encryptor) is the issuer that user delegated to issue the credential
    if $issuer_auth_public_key != $dwg_issuer_public_key {
        error('credentials issuer must be an issuer of delegated write grant (issuer_auth_public_key = dwg_issuer_public_key)');
    }

    $dwg_owner_found bool := false;
    for $row1 in SELECT 1 FROM wallets WHERE (wallet_type = 'EVM' AND address=$dwg_owner COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = $dwg_owner) {
        $dwg_owner_found := true;
        break;
    }
    if !$dwg_owner_found {
        error('dwg_owner not found');
    }

    -- Will fail if not in the RFC3339 format
    $ag_timelock = idos.parse_date($dwg_access_grant_timelock);

    -- Check the format and precedence
    if !idos.validate_not_usable_times($dwg_not_before, $dwg_not_after) {
        error('dwg_not_before must be before dwg_not_after');
    }

    -- Check if current block timestamp in time range allowed by write grant.
    -- @block_timestamp is a timestamp of previous block, which is can be a few seconds earlier
    -- (max is 6 seconds in current network consensus settings) then a time on a requester's machine.
    -- Also, if requester's machine has wrong time, it can be an issue.
    if parse_unix_timestamp($dwg_not_before, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')::int > (@block_timestamp + 6)
            OR @block_timestamp > parse_unix_timestamp($dwg_not_after, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')::int {

        error('this write grant can only be used after dwg_not_before and before dwg_not_after');
    }

    $dwg_result = idos.dwg_verify_owner(
        $dwg_owner,
        $dwg_grantee,
        $dwg_issuer_public_key,
        $dwg_id::TEXT,
        $dwg_access_grant_timelock,
        $dwg_not_before,
        $dwg_not_after,
        $dwg_signature
    );
    if !$dwg_result {
        error('verify owner failed');
    }

    $original_result = idos.assert_credential_signatures(
        $issuer_auth_public_key,
        $original_public_notes,
        $original_public_notes_signature,
        $original_content,
        $original_broader_signature
    );
    if !$original_result {
        error('an original credential signature is wrong');
    }


    $copy_result = idos.assert_credential_signatures(
        $issuer_auth_public_key,
        '',
        $copy_public_notes_signature,
        $copy_content,
        $copy_broader_signature
    );
    if !$copy_result {
        error('a copy credential signature is wrong');
    }


    -- Insert original credential
    $verifiable_credential_id = idos.get_verifiable_credential_id($original_public_notes);

    INSERT INTO credentials (id, user_id, verifiable_credential_id, public_notes, content, encryptor_public_key, issuer_auth_public_key, inserter)
    VALUES (
        $original_credential_id,
        (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=$dwg_owner COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = $dwg_owner)),
        CASE WHEN $verifiable_credential_id = '' THEN NULL ELSE $verifiable_credential_id END,
        $original_public_notes,
        $original_content,
        $original_encryptor_public_key,
        $issuer_auth_public_key,
        $dwg_id::TEXT
    );

    -- Insert copy credential
    INSERT INTO credentials (id, user_id, verifiable_credential_id, public_notes, content, encryptor_public_key, issuer_auth_public_key, inserter)
    VALUES (
        $copy_credential_id,
        (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=$dwg_owner COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = $dwg_owner)),
        NULL,
        '',
        $copy_content,
        $copy_encryptor_public_key,
        $issuer_auth_public_key,
        $dwg_id::TEXT
    );

    INSERT INTO shared_credentials (original_id, copy_id) VALUES ($original_credential_id, $copy_credential_id);

    create_access_grant(
        $dwg_grantee,
        $copy_credential_id,
        $ag_timelock,
        $content_hash,
        'delegated_write_grant',
        $dwg_id::TEXT
    );

    INSERT INTO consumed_write_grants (
        id,
        owner_wallet_identifier,
        grantee_wallet_identifier,
        issuer_public_key,
        original_credential_id,
        copy_credential_id,
        access_grant_timelock,
        not_usable_before,
        not_usable_after
    ) VALUES (
        $dwg_id,
        $dwg_owner,
        $dwg_grantee,
        $dwg_issuer_public_key,
        $original_credential_id,
        $copy_credential_id,
        $dwg_access_grant_timelock,
        $dwg_not_before,
        $dwg_not_after
    );
};

CREATE OR REPLACE ACTION credential_exist_as_inserter($id UUID) PUBLIC VIEW RETURNS (credential_exist BOOL) {
    get_inserter();
    return credential_exist($id);
};

CREATE OR REPLACE ACTION get_credential_owned ($id UUID) PUBLIC VIEW RETURNS table (
    id UUID,
    user_id UUID,
    public_notes TEXT,
    content TEXT,
    encryptor_public_key TEXT,
    issuer_auth_public_key TEXT,
    inserter TEXT
) {
    return SELECT DISTINCT c.id, c.user_id, c.public_notes, c.content, c.encryptor_public_key, c.issuer_auth_public_key, c.inserter
        FROM credentials AS c
        INNER JOIN wallets ON c.user_id = wallets.user_id
        WHERE c.id = $id
        AND (
            (wallets.wallet_type = 'EVM' AND wallets.address = @caller COLLATE NOCASE)
                OR (wallets.wallet_type = 'NEAR' AND wallets.public_key = @caller)
        );
};

-- As a credential copy doesn't contain PUBLIC notes, we return respective original credential PUBLIC notes
CREATE OR REPLACE ACTION get_credential_shared ($id UUID) PUBLIC VIEW RETURNS table (
    id UUID,
    user_id UUID,
    public_notes TEXT,
    content TEXT,
    encryptor_public_key TEXT,
    issuer_auth_public_key TEXT,
    inserter TEXT
) {
    if !credential_exist($id) {
        error('the credential does not exist');
    }

    $ag_granted bool := false;

    for $int_ag_row in SELECT 1 FROM access_grants WHERE data_id = $id AND ag_grantee_wallet_identifier = @caller COLLATE NOCASE {
        $ag_granted := true;
        break;
    }

    if !$ag_granted {
        error('the credential is not shared with the caller');
    }

    return SELECT c.id, c.user_id, oc.public_notes, c.content, c.encryptor_public_key, c.issuer_auth_public_key, c.inserter
        FROM credentials AS c
        LEFT JOIN shared_credentials ON c.id = shared_credentials.copy_id
        LEFT JOIN credentials as oc ON shared_credentials.original_id = oc.id
        WHERE c.id = $id;
    };

CREATE OR REPLACE ACTION get_sibling_credential_id ($content_hash TEXT) PUBLIC VIEW RETURNS (id UUID) {
    for $row in SELECT c.id FROM credentials as c INNER JOIN access_grants as ag ON c.id = ag.data_id
        WHERE ag.content_hash = $content_hash AND ag.ag_grantee_wallet_identifier = @caller COLLATE NOCASE {
            return $row.id;
        }
};

CREATE OR REPLACE ACTION credential_belongs_to_caller($id UUID) PRIVATE VIEW RETURNS (belongs BOOL) {
    for $row in SELECT 1 from credentials
        WHERE id = $id
        AND user_id=(SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller)) {
        return true;
    }

    return false;
};

CREATE OR REPLACE ACTION credential_exist($id UUID) PRIVATE VIEW RETURNS (credential_exist BOOL) {
    for $row in SELECT 1 FROM credentials WHERE id = $id {
        return true;
    }
    return false;
};


-- ATTRIBUTE ACTIONS

CREATE OR REPLACE ACTION add_attribute_as_inserter($id UUID, $user_id UUID, $attribute_key TEXT, $value TEXT) PUBLIC {
    $inserter := get_inserter();
    INSERT INTO user_attributes (id, user_id, attribute_key, value, inserter)
    VALUES ($id, $user_id, $attribute_key, $value, $inserter);
};

CREATE OR REPLACE ACTION add_attribute($id UUID, $attribute_key TEXT, $value TEXT) PUBLIC {
    INSERT INTO user_attributes (id, user_id, attribute_key, value)
    VALUES (
        $id,
        (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller)
        ),
        $attribute_key,
        $value
    );
};

CREATE OR REPLACE ACTION get_attributes() PUBLIC VIEW returns table (
    id UUID,
    user_id UUID,
    attribute_key TEXT,
    value TEXT,
    original_id UUID
) {
    return SELECT DISTINCT ha.id, ha.user_id, ha.attribute_key, ha.value, sha.original_id AS original_id
        FROM user_attributes AS ha
        LEFT JOIN shared_user_attributes AS sha ON ha.id = sha.copy_id
        INNER JOIN wallets ON ha.user_id = wallets.user_id
        WHERE (
            wallets.wallet_type = 'EVM' AND wallets.address = @caller COLLATE NOCASE
        ) OR (
            wallets.wallet_type = 'NEAR' AND wallets.public_key = @caller
        );
};

CREATE OR REPLACE ACTION edit_attribute($id UUID, $attribute_key TEXT, $value TEXT) PUBLIC {
    for $row in SELECT 1 FROM user_attributes AS ha
                INNER JOIN shared_user_attributes AS sha on ha.id = sha.copy_id
                WHERE ha.id = $id
                AND ha.user_id=(SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
                    OR (wallet_type = 'NEAR' AND public_key = @caller)) {
        error('Can not edit shared attribute');
    }

    UPDATE user_attributes
    SET attribute_key=$attribute_key, value=$value
    WHERE id=$id
    AND user_id=(SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
        OR (wallet_type = 'NEAR' AND public_key = @caller)
    );
};

CREATE OR REPLACE ACTION remove_attribute($id UUID) PUBLIC {
    DELETE FROM user_attributes
    WHERE id=$id
    AND user_id=(SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
        OR (wallet_type = 'NEAR' AND public_key = @caller)
    );
};

CREATE OR REPLACE ACTION share_attribute($id UUID, $original_attribute_id UUID, $attribute_key TEXT, $value TEXT) PUBLIC {
    INSERT INTO user_attributes (id, user_id, attribute_key, value)
    VALUES (
        $id,
        (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller)
        ),
        $attribute_key,
        $value
    );

    INSERT INTO shared_user_attributes (original_id, copy_id)
    VALUES ($original_attribute_id, $id);
};


-- DELEGATED WRITE GRANTS ACTIONS

CREATE OR REPLACE ACTION dwg_message(
    $owner_wallet_identifier TEXT,
    $grantee_wallet_identifier TEXT,
    $issuer_public_key TEXT,
    $id UUID,
    $access_grant_timelock TEXT, -- Must be in yyyy-mm-ddThh:mm:ssZ format
    $not_usable_before TEXT, -- Must be in yyyy-mm-ddThh:mm:ssZ format
    $not_usable_after TEXT -- Must be in yyyy-mm-ddThh:mm:ssZ format
) PUBLIC VIEW returns (message TEXT) {
    -- Will fail if not in the yyyy-mm-ddThh:mm:ssZ format, and not comply to RFC3339
    idos.parse_date($access_grant_timelock);

    -- Check the format and precedence
    if !idos.validate_not_usable_times($not_usable_before, $not_usable_after) {
        error('not_usable_before must be before not_usable_after');
    }

    return idos.dwg_message(
        $owner_wallet_identifier,
        $grantee_wallet_identifier,
        $issuer_public_key,
        $id::TEXT,
        $access_grant_timelock,
        $not_usable_before,
        $not_usable_after
    );
};

-- DELEGATED INSERT GRANTS ACTIONS

CREATE OR REPLACE ACTION dig_message(
    $owner_wallet_identifier TEXT,
    $issuer_public_key TEXT,
    $id UUID,
    $not_usable_before TEXT, -- Must be in yyyy-mm-ddThh:mm:ssZ format
    $not_usable_after TEXT -- Must be in yyyy-mm-ddThh:mm:ssZ format
) PUBLIC VIEW returns (message TEXT) {
    -- Check the format and precedence
    -- Will fail if a time not in the yyyy-mm-ddThh:mm:ssZ format, and not comply to RFC3339
    if !idos.validate_not_usable_times($not_usable_before, $not_usable_after) {
        error('not_usable_before must be before not_usable_after');
    }

    return idos.dig_message(
        $owner_wallet_identifier,
        $issuer_public_key,
        $id::TEXT,
        $not_usable_before,
        $not_usable_after
    );
};


-- ACCESS GRANTS ACTIONS

CREATE OR REPLACE ACTION revoke_access_grant ($id UUID) PUBLIC {
    $ag_exist := false;
    for $row in SELECT 1 FROM access_grants WHERE id = $id
        AND ag_owner_user_id = (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller)) {
        $ag_exist := true;
    }

    if !$ag_exist {
        error('the access grant not found');
    }

    for $row2 in SELECT 1 FROM access_grants WHERE id = $id
        AND locked_until >= @block_timestamp
        AND ag_owner_user_id = (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller)) {
        error('the grant is locked');
    }

    DELETE FROM access_grants
    WHERE id = $id
    AND ag_owner_user_id = (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
        OR (wallet_type = 'NEAR' AND public_key = @caller));
};

CREATE OR REPLACE ACTION get_access_grants_owned () PUBLIC VIEW RETURNS table (
    id UUID,
    ag_owner_user_id UUID,
    ag_grantee_wallet_identifier TEXT,
    data_id UUID,
    locked_until INT,
    content_hash TEXT,
    inserter_type TEXT,
    inserter_id TEXT
) {
    return SELECT id, ag_owner_user_id, ag_grantee_wallet_identifier, data_id, locked_until, content_hash, inserter_type, inserter_id FROM access_grants
        WHERE ag_owner_user_id = (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
            OR (wallet_type = 'NEAR' AND public_key = @caller));
};

-- As arguments can be undefined (user can not send them at all), we have to have default values: page=1, size=20
-- Page number starts from 1, as UI usually shows to user in pagination element
-- Ordering is consistent because we use height as first ordering parameter
CREATE OR REPLACE ACTION get_access_grants_granted ($user_id UUID, $page INT, $size INT) PUBLIC VIEW RETURNS table (
    id UUID,
    ag_owner_user_id UUID,
    ag_grantee_wallet_identifier TEXT,
    data_id UUID,
    locked_until INT,
    content_hash TEXT,
    inserter_type TEXT,
    inserter_id TEXT
) {
    $index int := 0;
    if $page < 1 {
        error('page has to be a positive integer');
    } else {
        $index := $page - 1;
    }

    $limit int := 20;
    if $size < 1 {
        error('size has to be a positive integer');
    } else {
        $limit := $size;
    }

    $offset int := $index * $limit;

    if $user_id is null {
      return SELECT id, ag_owner_user_id, ag_grantee_wallet_identifier, data_id, locked_until, content_hash, inserter_type, inserter_id
        FROM access_grants
        WHERE ag_grantee_wallet_identifier = @caller COLLATE NOCASE
        ORDER BY height ASC, id ASC LIMIT $limit OFFSET $offset;
    } else {
      return SELECT id, ag_owner_user_id, ag_grantee_wallet_identifier, data_id, locked_until, content_hash, inserter_type, inserter_id
        FROM access_grants
        WHERE ag_grantee_wallet_identifier = @caller COLLATE NOCASE
            AND ag_owner_user_id = $user_id
        ORDER BY height ASC, id ASC LIMIT $limit OFFSET $offset;
    }
};

CREATE OR REPLACE ACTION get_access_grants_granted_count ($user_id UUID) PUBLIC VIEW RETURNS (count INT) {
    if $user_id is null {
      for $row in SELECT COUNT(1) as count FROM access_grants WHERE ag_grantee_wallet_identifier =  @caller COLLATE NOCASE {
        return $row.count;
      }
    } else {
      for $row in SELECT COUNT(1) as count FROM access_grants
        WHERE ag_grantee_wallet_identifier =  @caller COLLATE NOCASE
            AND ag_owner_user_id = $user_id {
        return $row.count;
      }
    }
};

CREATE OR REPLACE ACTION has_locked_access_grants($id UUID) PUBLIC VIEW RETURNS (has BOOL) {
    for $ag_row in SELECT 1 FROM access_grants
            WHERE data_id = $id
            AND ag_owner_user_id = (SELECT DISTINCT user_id FROM wallets WHERE (wallet_type = 'EVM' AND address=@caller COLLATE NOCASE)
                OR (wallet_type = 'NEAR' AND public_key = @caller))
            AND locked_until >= @block_timestamp LIMIT 1 {
        return true;
    }

    return false;
};

CREATE OR REPLACE ACTION dag_message(
    $dag_owner_wallet_identifier TEXT,
    $dag_grantee_wallet_identifier TEXT,
    $dag_data_id UUID,
    $dag_locked_until INT,
    $dag_content_hash TEXT
) PUBLIC VIEW returns (message TEXT) {
    return idos.dag_message(
        $dag_owner_wallet_identifier,
        $dag_grantee_wallet_identifier,
        $dag_data_id::TEXT,
        $dag_locked_until,
        $dag_content_hash
    );
};

CREATE OR REPLACE ACTION create_ag_by_dag_for_copy(
    $dag_owner_wallet_identifier TEXT,
    $dag_grantee_wallet_identifier TEXT,
    $dag_data_id UUID,
    $dag_locked_until INT,
    $dag_content_hash TEXT,
    $dag_signature TEXT
) PUBLIC {
    -- This works for EVM-compatible signatures only
    $owner_verified = idos.verify_owner(
        $dag_owner_wallet_identifier,
        $dag_grantee_wallet_identifier,
        $dag_data_id::TEXT,
        $dag_locked_until,
        $dag_content_hash,
        $dag_signature
    );
    if !$owner_verified {
        error('the dag_signature is invalid');
    }

    $data_id_belongs_to_owner bool := false;
    for $row in SELECT 1 from credentials
            INNER JOIN wallets ON credentials.user_id = wallets.user_id
            WHERE credentials.id = $dag_data_id
            AND wallets.address = $dag_owner_wallet_identifier COLLATE NOCASE
            AND wallets.wallet_type = 'EVM' {
        $data_id_belongs_to_owner := true;
        break;
    }
    if !$data_id_belongs_to_owner {
        error('the data_id does not belong to the owner');
    }

    create_access_grant(
        $dag_grantee_wallet_identifier,
        $dag_data_id,
        $dag_locked_until::int,
        $dag_content_hash,
        'dag_message',
        @caller
    );
};

CREATE OR REPLACE ACTION create_access_grant(
    $grantee_wallet_identifier TEXT,
    $data_id UUID,
    $locked_until INT,
    $content_hash TEXT,
    $inserter_type TEXT,
    $inserter_id TEXT
) PRIVATE {
    $user_id TEXT := '';
    for $row in SELECT user_id from credentials WHERE id = $data_id {
        $user_id := $row.user_id::TEXT;
        break;
    }
    -- data_id is an id of a copy. It always has a user. So if no user found then there is no credential found.
    if $user_id == '' {
        error('the credential, that the AG is for, does not exist');
    }

    for $row3 in SELECT 1 FROM access_grants WHERE id = uuid_generate_v5('31276fd4-105f-4ff7-9f64-644942c14b79'::UUID, format('%s-%s-%s', $grantee_wallet_identifier, $data_id, $locked_until::TEXT)) {
        error('a grant with the same grantee, copy_credential_id, and locked_until already exists');
    }


    INSERT INTO access_grants (
        id,
        ag_owner_user_id,
        ag_grantee_wallet_identifier,
        data_id,
        locked_until,
        content_hash,
        height,
        inserter_type,
        inserter_id
    ) VALUES (
        uuid_generate_v5('31276fd4-105f-4ff7-9f64-644942c14b79'::UUID, format('%s-%s-%s', $grantee_wallet_identifier, $data_id, $locked_until::TEXT)),
        $user_id::UUID,
        $grantee_wallet_identifier,
        $data_id,
        $locked_until,
        $content_hash,
        @height,
        $inserter_type,
        $inserter_id
    );
};

CREATE OR REPLACE ACTION get_access_grants_for_credential($credential_id UUID) PUBLIC VIEW RETURNS table (
    id UUID,
    ag_owner_user_id UUID,
    ag_grantee_wallet_identifier TEXT,
    data_id UUID,
    locked_until INT,
    content_hash TEXT,
    inserter_type TEXT,
    inserter_id TEXT
) {
    return SELECT id, ag_owner_user_id, ag_grantee_wallet_identifier, data_id, locked_until, content_hash, inserter_type, inserter_id
        FROM access_grants WHERE data_id = $credential_id AND ag_grantee_wallet_identifier = @caller COLLATE NOCASE;
};

-- OTHER ACTIONS

-- Should we improve it to work with near wallets too?
CREATE OR REPLACE ACTION has_profile($address TEXT) PUBLIC VIEW returns (has_profile BOOL) {
    for $row in SELECT 1 FROM wallets WHERE address=$address COLLATE NOCASE {
        return true;
    }

    return false;
};


-- OWNER ACTIONS FOR MANUAL MIGRATIONS

CREATE OR REPLACE ACTION insert_user_as_owner($id UUID, $recipient_encryption_public_key TEXT, $inserter TEXT) OWNER PUBLIC {
    INSERT INTO users (id, recipient_encryption_public_key, inserter)
    VALUES ($id, $recipient_encryption_public_key, $inserter);
};

CREATE OR REPLACE ACTION insert_wallet_as_owner($id UUID, $user_id UUID, $address TEXT, $public_key TEXT, $wallet_type TEXT,
    $message TEXT, $signature TEXT, $inserter TEXT) OWNER PUBLIC {
    INSERT INTO wallets (id, user_id, address, public_key, wallet_type, message, signature, inserter)
    VALUES ($id, $user_id, $address, $public_key, $wallet_type, $message, $signature, $inserter);
};

CREATE OR REPLACE ACTION insert_credential_as_owner (
    $id UUID,
    $user_id UUID,
    $verifiable_credential_id TEXT,
    $public_notes TEXT,
    $content TEXT,
    $encryptor_public_key TEXT,
    $issuer_auth_public_key TEXT,
    $inserter TEXT
) OWNER PUBLIC {
    INSERT INTO credentials (id, user_id, verifiable_credential_id, public_notes, content, encryptor_public_key, issuer_auth_public_key, inserter)
    VALUES ($id, $user_id, $verifiable_credential_id, $public_notes, $content, $encryptor_public_key, $issuer_auth_public_key, $inserter);
};

CREATE OR REPLACE ACTION insert_shared_cred_as_owner($original_id UUID, $copy_id UUID) OWNER PUBLIC {
    INSERT INTO shared_credentials (original_id, copy_id)
    VALUES ($original_id, $copy_id);
};

CREATE OR REPLACE ACTION insert_user_attribute_as_owner($id UUID, $user_id UUID, $attribute_key TEXT, $value TEXT, $inserter TEXT) OWNER PUBLIC {
    INSERT INTO user_attributes (id, user_id, attribute_key, value, inserter)
    VALUES ($id, $user_id, $attribute_key, $value, $inserter);
};

CREATE OR REPLACE ACTION insert_shared_attr_as_owner($original_id UUID, $copy_id UUID) OWNER PUBLIC {
    INSERT INTO shared_user_attributes (original_id, copy_id)
    VALUES ($original_id, $copy_id);
};

-- Some entities no need special actions because main actions do the same
-- inserters:  add_inserter_as_owner
-- delegates: add_delegate_as_owner

CREATE OR REPLACE ACTION insert_access_grants_as_owner($id UUID, $ag_owner_user_id UUID, $ag_grantee_wallet_identifier TEXT, $data_id UUID,
$locked_until int, $content_hash TEXT, $height int, $inserter_type TEXT, $inserter_id TEXT) OWNER PUBLIC {
    INSERT INTO access_grants (id, ag_owner_user_id, ag_grantee_wallet_identifier, data_id, locked_until, content_hash, height, inserter_type, inserter_id)
    VALUES ($id, $ag_owner_user_id, $ag_grantee_wallet_identifier, $data_id, $locked_until, $content_hash, $height, $inserter_type, $inserter_id);
};

CREATE OR REPLACE ACTION insert_consumed_wgs_as_owner($id UUID, $owner_wallet_identifier TEXT, $grantee_wallet_identifier TEXT,
$issuer_public_key TEXT, $original_credential_id UUID, $copy_credential_id UUID, $access_grant_timelock TEXT,
$not_usable_before TEXT, $not_usable_after TEXT) OWNER PUBLIC {
    INSERT INTO consumed_write_grants (id, owner_wallet_identifier, grantee_wallet_identifier, issuer_public_key, original_credential_id,
        copy_credential_id, access_grant_timelock, not_usable_before, not_usable_after)
    VALUES ($id, $owner_wallet_identifier, $grantee_wallet_identifier, $issuer_public_key, $original_credential_id,
        $copy_credential_id, $access_grant_timelock, $not_usable_before, $not_usable_after);
};

CREATE OR REPLACE ACTION insert_consumed_igs_as_owner($id UUID, $owner_wallet_identifier TEXT, $issuer_public_key TEXT,
$credential_id UUID, $not_usable_before TEXT, $not_usable_after TEXT) OWNER PUBLIC {
    INSERT INTO consumed_insert_grants (id, owner_wallet_identifier, issuer_public_key, credential_id, not_usable_before, not_usable_after)
    VALUES ($id, $owner_wallet_identifier, $issuer_public_key, $credential_id, $not_usable_before, $not_usable_after);
};
