-- TOKEN BRIDGE EXTENSIONS

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_sepolia',
    escrow: '0x1Cb4879cD8B714FC6c98a49248451C2Cc55b64E1',
    distribution_period: '10m'
} AS idos_token_bridge;

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_sepolia',
    escrow: '0x3593DA8aEEffc4Af3DC63122d23b77087C8892F7',
    distribution_period: '10m'
} AS usdc_token_bridge;


-- GAS CAPTURE AMOUNT

CREATE OR REPLACE ACTION gas_capture_amount() PRIVATE VIEW RETURNS (amount NUMERIC(6,2)) {
    RETURN 0::NUMERIC(6,2);
};


-- TEST ACTIONS FOR GAS AND FEE CAPTURE (staging only, not in schema.sql)

CREATE OR REPLACE ACTION action_costing_gas() PUBLIC {
    capture_gas(1.2::NUMERIC(6,2));
};

CREATE OR REPLACE ACTION action_costing_idos_token($amount NUMERIC(78,0)) PUBLIC {
    IF $amount IS NULL { ERROR('amount is required'); }
    IF $amount < 0::NUMERIC(78,0) { ERROR('amount cannot be negative'); }
    IF $amount == 0::NUMERIC(78,0) { RETURN; }

    $evm_address := get_wallet_with_balance('IDOS', $amount);
    if $evm_address is null {
        ERROR('no wallet with balance found');
    }

    idos_token_bridge.lock_admin($evm_address, $amount);
};

CREATE OR REPLACE ACTION action_costing_fee($credential_id UUID) PUBLIC {
    capture_fee($credential_id);
};
