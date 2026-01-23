-- TOKEN BRIDGE EXTENSIONS

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_one',
    escrow: '0x0dc9A81e5E170D85885F8151F51aA5160A0a3C7C',
    distribution_period: '10m'
} AS idos_token_bridge;

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_one',
    escrow: '0x2Ea8775B281287594FD0a3D68e12100cEC754f47',
    distribution_period: '10m'
} AS usdc_token_bridge;
