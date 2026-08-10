ALTER TABLE wallets ADD CHECK (wallet_type IN ('EVM', 'NEAR', 'XRPL', 'Stellar', 'FaceSign', 'MM'));
