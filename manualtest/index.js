const ethers = require("ethers");
const namehash = require('eth-ens-namehash');
const sha3 = require('js-sha3').keccak_256
const crypto = require('crypto');

const ZERO_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

const decentraNameControllerABI = require('../build/contracts/DecentraNameController.json');
//const dummyOracleABI = require('../build/contracts/DummyOracle.json');
const priceEstimatorABI = require('../build/contracts/PriceEstimator.json');
const stablePriceOracleABI = require('../build/contracts/StablePriceOracle.json');
const ensRegistryABI = require('../build/contracts/ENSRegistry.json');
const rootABI = require('../build/contracts/Root.json');
const decentraWebTokenABI = require('../build/contracts/DecentraWebToken.json');
const rootRegistrarControllerABI = require('../build/contracts/RootRegistrarController.json');

const decentraNameABI = require('../build/contracts/DecentraName.json');

const jsonPath = "../deployments/rinkeby/";

const decentraNameAddr = '0xC4DaCE03731D2A9Eb795aC980cD0831dDB4332Eb';

const decentraNameControllerAddr = JSON.parse(JSON.stringify(require(jsonPath + "DecentraNameController.json")))['address'];
//const dummyOracleAddr = '0xac98ae75daa00ddc1996ad3a87135c19c346ce81';
const priceEstimatorAddr = JSON.parse(JSON.stringify(require(jsonPath + "StablePriceOracle.json")))['args'][0];
const stablePriceOracleAddr = JSON.parse(JSON.stringify(require(jsonPath + "StablePriceOracle.json")))['address'];
const ensRegistryAddr = JSON.parse(JSON.stringify(require(jsonPath + "ENSRegistry.json")))['address'];
const rootAddr = JSON.parse(JSON.stringify(require(jsonPath + "Root.json")))['address'];
const decentraWebTokenAddr = JSON.parse(JSON.stringify(require(jsonPath + "RootRegistrarController.json")))['args'][2];
const rootRegistrarControllerAddr = JSON.parse(JSON.stringify(require(jsonPath + "RootRegistrarController.json")))['address'];



// const RPCUrl = 'http://127.0.0.1:7545';
const RPCUrl = 'https://rinkeby.infura.io/v3/a179f100768a423fa0eebdcbc984b61b';


const deployer = "0x4CeBBdbBdFe8A1BB3F62A75B5fe9ebaE5D105f8F";
const deployerpri = "253dd8a564bb1525bbcf322346d0524c4aaebe878b582acbf92e386177020c8c";
const acc2 = "0x71504cbCD9E376C2f6CF791C91349B45c387Fa88"
const acc2pri = "fd310b1dacfad5ccdb8274c69cefde7b11fa9e9e97caec4edf6d6b2bc51ce414";
const acc3 = "0x654B39F5a9fC17340eE711B0C7fc0423108251E7";
const acc3pri = "c7313b9b823b55bbff5e70d425aab815ab04ad7e9d9227ae9cf41e8b256d5aba";
const acc4 = "0xf91eF62a17E9A3669c20088FB74E918Ecb01DAB1";
// const acc4pri = "39d9f533e3045cdc3a0ac8d3a117efa9b35a8b9ae9634bba4d798cada7fc400f";


const provider = new ethers.providers.JsonRpcProvider(RPCUrl);
const deployerWallet = new ethers.Wallet(deployerpri, provider);
const wallet2 = new ethers.Wallet(acc2pri, provider);
const wallet3 = new ethers.Wallet(acc3pri, provider);

const decentraNameControllerContract = new ethers.Contract(decentraNameControllerAddr, JSON.parse(JSON.stringify(decentraNameControllerABI)), provider);
//const dummyOracleContract = new ethers.Contract(dummyOracleAddr, JSON.parse(JSON.stringify(dummyOracleABI)), provider);
const priceEstimatorContract = new ethers.Contract(priceEstimatorAddr, JSON.parse(JSON.stringify(priceEstimatorABI)), provider);
const stablePriceOracleContract = new ethers.Contract(stablePriceOracleAddr, JSON.parse(JSON.stringify(stablePriceOracleABI)), provider);
const ensRegistryContract = new ethers.Contract(ensRegistryAddr, JSON.parse(JSON.stringify(ensRegistryABI)), provider);
const rootContract = new ethers.Contract(rootAddr, JSON.parse(JSON.stringify(rootABI)), provider);
const decentraWebTokenContract = new ethers.Contract(decentraWebTokenAddr, JSON.parse(JSON.stringify(decentraWebTokenABI)), provider);
const rootRegistrarControllerContract = new ethers.Contract(rootRegistrarControllerAddr, JSON.parse(JSON.stringify(rootRegistrarControllerABI)), provider);
var decentraNameContract = new ethers.Contract(decentraNameAddr, JSON.parse(JSON.stringify(decentraNameABI)), provider);


async function makeCommitment(name, owner, secret, r, s, v) {
    
    const commitment = await rootRegistrarControllerContract.connect(wallet2).makeCommitment(name, owner, secret);
    await rootRegistrarControllerContract.connect(wallet2).commit(commitment, r, s, v);
}

async function commit(name, owner, secret, r, s, v) {
    await makeCommitment(name, owner, secret, r, s, v);
}

async function register(domainName, owner, duration, secret) {
    const isDWEB = true;
    await commit(domainName, owner, secret, '0x00', ZERO_HASH, ZERO_HASH);

    let price = await rootRegistrarControllerContract.connect(wallet2).rentPrice(domainName, duration, isDWEB);
    // add 10% buffer
    price = price.mul(110).div(100);

    if(isDWEB) {
        console.log(`calculated dweb price: ${price /* / 1000000000000000000*/}`);
        // set approve
        const currentApprovedAmount = await decentraWebTokenContract.allowance(owner, rootRegistrarControllerAddr);
        console.log(`Approved amount ${currentApprovedAmount}`);

        // TODO-review
        if(price > currentApprovedAmount) {
            console.log(`requesting approval for ${price} dweb`);
            await decentraWebTokenContract.connect(wallet2).approve(rootRegistrarControllerAddr, (price).toString());
        }

        console.log('Waiting for 60 sec');
        await new Promise(r => setTimeout(r, 60000));

        // register
        const gasLimit = ethers.utils.parseUnits('2000000', 'wei');
        await rootRegistrarControllerContract.connect(wallet2).register(domainName, owner, duration, secret, isDWEB, price.toString(), {value: '0x0', gasLimit});
    } else {
        console.log('Waiting for 60 sec');
        await new Promise(r => setTimeout(r, 60000));
        
        console.log(`calculated eth price: ${ethers.utils.formatUnits(price, 'ether')}`);
        const gasLimit = ethers.utils.parseUnits('2000000', 'wei');
        await rootRegistrarControllerContract.connect(wallet2).register(domainName, owner, duration, secret, isDWEB, price, {value: price, gasLimit});
    }
    
}

async function getOwner(domainName) {
    const label = namehash.hash(domainName);
    return await decentraNameControllerContract.connect(wallet2).ownerOf(label);
}

async function createSubDomain(parent, label, owner) {
    const subnode = await ensRegistryContract.connect(wallet2).createSubnode(namehash.hash(parent), '0x' + sha3(namehash.normalize(label)), owner);
    console.log(`subnode created ${subnode}`);
}

async function transferDomain(node, owner) {
    await decentraNameContract.connect(wallet2).setApprovalForAll(decentraNameControllerAddr, true);
    await ensRegistryContract.connect(wallet2).setOwner(namehash.hash(node), owner);
}

async function transferSubDomain(parent, label, owner) {
    await decentraNameContract.connect(wallet2).setApprovalForAll(decentraNameControllerAddr, true);
    await ensRegistryContract.connect(wallet2).setSubnodeOwner(namehash.hash(parent), '0x' + sha3(namehash.normalize(label)), owner);
}

async function main () {

    //let wallet1 = new ethers.Wallet(acc1);
    // let signedMsg = await wallet.signMessage(binaryData)
    // contract.connect(wallet);

    // let wallet = new ethers.Wallet(privateKey, provider);
    // let tx = wallet.sendTransaction(tx);

    // console.log(`Is domain exist: ${await decentraNameContract.existsToken(namehash.hash('abc'))}`);
    
    const tld = 'abi'

    // Register domain
    await register(tld, acc2, 31556926, '0x' + crypto.randomBytes(32).toString('hex'));

    // console.log(`Owner is ${await getOwner(`${tld}`)}`);
    // transfer root domain
    // await transferDomain(`abe`, acc3);

    // console.log(`Owner is ${await getOwner(`abe`)}`);

    // const subdomain = 'sub1'
    // // create subdomain acc2.abc
    // await createSubDomain(tld, subdomain, acc2);
    // console.log(`Owner is ${await getOwner(`${subdomain}.${tld}`)}`);


    // // Transfer subdomain
    // await transferSubDomain(tld, subdomain, acc3);
    // console.log(`Owner is ${await getOwner(`${subdomain}.${tld}`)}`);

    // // Transfer domain acc2.abc
    // await transferDomain(`${subdomain}.${tld}`, acc3);

    // console.log(`Owner is ${await getOwner(`${subdomain}.${tld}`)}`);

    // set domain price
    // const prices = [5000_000, 1200_000, 40_000];
    // await stablePriceOracleContract.connect(deployerWallet).setPrices(prices);
    // console.log(await stablePriceOracleContract.rentPrices(0));
    // console.log(await stablePriceOracleContract.rentPrices(1));
    // console.log(await stablePriceOracleContract.rentPrices(2));

    // console.log(`uniswapV2Pair addr: ${await decentraWebTokenContract.uniswapV2Pair()}`);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });