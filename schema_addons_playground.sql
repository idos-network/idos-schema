-- TOKEN BRIDGE EXTENSIONS

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_sepolia',
    escrow: '0x52e61A649e332D5Eab8341D9718f3fc9d79D79b4',
    distribution_period: '10m'
} AS idos_token_bridge;

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_sepolia',
    escrow: '0xc04B5e4b3FC510168aebF07C9ab9507D64800B51',
    distribution_period: '10m'
} AS usdc_token_bridge;
