-- TOKEN BRIDGE EXTENSIONS

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_sepolia',
    escrow: '0x52DE0ea92Fe07074D053a3216b391C412d5b548f',
    distribution_period: '10m'
} AS idos_token_bridge;

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_sepolia',
    escrow: '0x581A97E0D924b23DE5A641ec354739478d0900e2',
    distribution_period: '10m'
} AS usdc_token_bridge;
