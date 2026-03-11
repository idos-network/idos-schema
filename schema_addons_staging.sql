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
