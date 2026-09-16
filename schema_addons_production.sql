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


-- GAS CAPTURE AMOUNT

CREATE OR REPLACE ACTION gas_capture_amount() PRIVATE VIEW RETURNS (amount NUMERIC(6,2)) {
    RETURN 0.01::NUMERIC(6,2);
};
