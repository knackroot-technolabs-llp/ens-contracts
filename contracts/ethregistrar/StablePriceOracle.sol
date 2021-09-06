pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "./SafeMath.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../decentraname/IERC20Extended.sol";
import "./IPriceEstimator.sol";

// StablePriceOracle sets a price in USD, based on an oracle.
contract StablePriceOracle is Ownable, PriceOracle {
    using SafeMath for *;
    using StringUtils for *;

    // Rent in base price units by length. Element 0 is for 1-length names, and so on.
    // price in USDT (USD * 1e6)
    // price is of 1 year
    uint[] public rentPrices;

    // Oracle address
    IPriceEstimator public priceEstimator;

    // actual value in the format val * 1e-1  e.g. set value 3 for 0.3
    uint256 private uniswapFeePercentage;

    address private usdTokenAddress;

    //event OracleChanged(address oracle);

    event RentPriceChanged(uint[] prices);

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ORACLE_ID = bytes4(keccak256("price(string,uint256,uint256)") ^ keccak256("premium(string,uint256,uint256)"));

    constructor(IPriceEstimator _priceEstimator, address _usdTokenAddress, uint[] memory _rentPrices) public {
        priceEstimator = _priceEstimator;
        usdTokenAddress = _usdTokenAddress;
        setPrices(_rentPrices);
    }

    // returns price in wei or ERC20 token decimal
    function price(string calldata name, uint expires, uint duration, bool isFeeInDWEBToken, address dWebTokenAddress) external view override returns(uint256) {
        uint len = name.strlen();
        if(len > rentPrices.length) {
            len = rentPrices.length;
        }
        require(len > 0);
        
        // convert duration from seconds to years since price is of 1 year
        uint basePrice = rentPrices[len - 1].mul(duration).div(31556926);
        basePrice = basePrice.add(_premium(name, expires, duration));

        //return attoUSDToWei(basePrice);

        uint256 minRequiredFee;
        if(isFeeInDWEBToken) {
            minRequiredFee = getFeesInDWEBToken(basePrice, dWebTokenAddress);
        } else {
            minRequiredFee = getFeesInWei(basePrice);
        }
        return minRequiredFee;
    }

    /**
     * @dev Sets rent prices.
     * @param _rentPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setPrices(uint[] memory _rentPrices) public onlyOwner {
        rentPrices = _rentPrices;
        emit RentPriceChanged(_rentPrices);
    }

    /**
     * @dev Sets the price oracle address
     * @param _priceEstimator The address of the price estimator to use.
     */
    function setPriceEstimator(IPriceEstimator _priceEstimator) public onlyOwner {
        priceEstimator = _priceEstimator;
        
        // TODO-event : event needs to be changed
        //emit OracleChanged(address(_usdOracle));
    }

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(string calldata name, uint expires, uint duration) external view returns(uint) {
        // TODO-enhancement: may need to convert the returned price
        return _premium(name, expires, duration);
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory name, uint expires, uint duration) virtual internal view returns(uint) {
        return 0;
    }

    // function attoUSDToWei(uint amount) internal view returns(uint) {
    //     uint ethPrice = uint(usdOracle.latestAnswer());
    //     return amount.mul(1e8).div(ethPrice);
    // }

    // function weiToAttoUSD(uint amount) internal view returns(uint) {
    //     uint ethPrice = uint(usdOracle.latestAnswer());
    //     return amount.mul(ethPrice).div(1e8);
    //}

    function getFeesInDWEBToken(uint basePrice, address dWebToken) internal view returns (uint256) {
        uint256 feesInWei = getFeesInWei(basePrice);
        
        // 50% discount in dweb
        uint256 feesInWeiIfPaidViaDWEB = feesInWei.div(2);
        // convert wei to dweb decimal
        uint256 dwebPerEth = priceEstimator.getEstimatedERC20forETH(1, dWebToken)[0];
        //subtract uniswap 0.30% fees
        // TODO: see if returned price is included 0.3% or not
        uint256 estDWEBPerEth = dwebPerEth.sub(dwebPerEth.mul(uniswapFeePercentage).div(1000));

        // fees in dweb token
        return feesInWeiIfPaidViaDWEB.mul(estDWEBPerEth);
    }
    
    function getFeesInWei(uint basePrice) internal view returns (uint256) {
        //price should be estimated by 1 token because Uniswap algo changes price based on large amount
        uint256 tokenBits = 10 ** uint256(IERC20Extended(usdTokenAddress).decimals()); // 1e6 for USDT
        uint256 estFeesInWeiPerUnit = priceEstimator.getEstimatedETHforERC20(tokenBits, usdTokenAddress)[0];
        //subtract uniswap 0.30% fees
        //uniswapFeePercentage is a percentage expressed in 1/10 (a tenth) of a percent hence we divide by 1000
        estFeesInWeiPerUnit = estFeesInWeiPerUnit.sub(estFeesInWeiPerUnit.mul(uniswapFeePercentage).div(1000));

        // fees in wei 
        return basePrice.mul(estFeesInWeiPerUnit).div(tokenBits);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}
