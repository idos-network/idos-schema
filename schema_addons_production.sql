-- TOKEN BRIDGE EXTENSIONS

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_one',
    escrow: '0xBe34524b5CcEb47eEf931D71c77156F5EeA4d677',
    distribution_period: '10m'
} AS idos_token_bridge;

USE IF NOT EXISTS erc20 {
    chain: 'arbitrum_one',
    escrow: '0x8444FC33A0c6135B829d020821D42F2E7E81151f',
    distribution_period: '10m'
} AS usdc_token_bridge;
