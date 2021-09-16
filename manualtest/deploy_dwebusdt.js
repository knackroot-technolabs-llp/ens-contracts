const { ethers, upgrades } = require("hardhat");

async function main() {
  const Greeter = await ethers.getContractFactory("DecentraWebUSDTToken");
  const greeter = await Greeter.deploy();

  const decentraWebUSDTToken = await ethers.getContractFactory("DecentraWebUSDTToken");
    const decentraWebUSDTTokenProxy = await upgrades.deployProxy(decentraWebUSDTToken);
    await decentraWebUSDTTokenProxy.deployed();

  console.log("DecentraWebUSDTToken deployed to:", decentraWebUSDTTokenProxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
