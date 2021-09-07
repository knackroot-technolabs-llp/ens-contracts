const { ethers } = require("hardhat");

const ZERO_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    // // dummy price oracle
    // const dummyOracleEthPrice = 3200; // USD  // price mul 1e8
    // const dummyPracle = await deploy('DummyOracle', {
    //     from: deployer,
    //     args: [dummyOracleEthPrice],
    //     log: true
    // });
    // console.log(`### DummyOracle deployed at ${dummyPracle.address}`);

    const usdtAddr = network.tags.test ? process.env.USDT_ADDR_RINKEBY : process.env.USDT_ADDR;
    console.log(`usdt addr is ${usdtAddr}`);
    const uniswapV2Addr = network.tags.test ? process.env.UNISWAP_V2_ADDR_RINKEBY : process.env.UNISWAP_V2_ADDR;
    console.log(`uniswap v2 addr is ${uniswapV2Addr}`);

    const priceEstimator = await deploy('PriceEstimator', {
        from: deployer,
        args: [],
        log: true
    });

    // initialize PriceEstimator
    const priceEstimatorContract = await ethers.getContract('PriceEstimator');
    await priceEstimatorContract.initialize(uniswapV2Addr);
    console.log(`PriceEstimator initialized successfully`);

    console.log(`### priceEstimator deployed at ${priceEstimator.address}`);

    // TODO: set actual price
    const prices = [5000000000, 1200000000, 40000000]; // price mul 1e8 e.g. 5000 * 1e6

    const stablePriceOracle = await deploy('StablePriceOracle', {
        from: deployer,
        args: [priceEstimator.address, usdtAddr, prices],
        log: true
    });

    console.log(`### StablePriceOracle deployed at ${stablePriceOracle.address}`);

    return true;
};
module.exports.tags = ['StablePriceOracle'];
module.exports.id = "StablePriceOracle";
