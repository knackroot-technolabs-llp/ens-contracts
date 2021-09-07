const { ethers, upgrades } = require("hardhat");

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

    const priceEstimator = await ethers.getContractFactory("PriceEstimator");
    const priceEstimatorProxy = await upgrades.deployProxy(priceEstimator, [uniswapV2Addr]);
    await priceEstimatorProxy.deployed();

    console.log(`### priceEstimator deployed at ${priceEstimatorProxy.address}`);

    // TODO: set actual price
    const prices = [5000_000000, 1200_000000, 40_000000]; // price mul 1e8 e.g. 5000 * 1e6

    const stablePriceOracle = await deploy('StablePriceOracle', {
        from: deployer,
        args: [priceEstimatorProxy.address, usdtAddr, prices],
        log: true
    });

    console.log(`### StablePriceOracle deployed at ${stablePriceOracle.address}`);

    return true;
};
module.exports.tags = ['StablePriceOracle'];
module.exports.id = "StablePriceOracle";
