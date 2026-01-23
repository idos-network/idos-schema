-- TOKEN BRIDGE EXTENSIONS

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_one',
    escrow: '0xB479B9A1B3c2B5fBCcE6F9F9fDcd2EEBD29c2123',
    distribution_period: '10m'
} AS idos_token_bridge;

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_one',
    escrow: '0x0e9b19b5E3363421C0C119403230607CDCb65019',
    distribution_period: '10m'
} AS usdc_token_bridge;
