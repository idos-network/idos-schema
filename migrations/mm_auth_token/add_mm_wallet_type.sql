ALTER TABLE wallets DROP CONSTRAINT wallets_wallet_type_check;
ALTER TABLE wallets ADD CHECK (wallet_type IN ('EVM', 'NEAR', 'XRPL', 'Stellar', 'FaceSign', 'MM'));
