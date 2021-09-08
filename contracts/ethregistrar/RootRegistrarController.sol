pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "../root/Root.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../resolvers/Resolver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract RootRegistrarController is Ownable {
    using StringUtils for *;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint constant public MIN_REGISTRATION_DURATION = 31556926; // 1 year
    uint constant public MAX_REGISTRATION_DURATION = 157784630; // 5 years

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("rentPrice(string,uint256)") ^
        keccak256("available(string)") ^
        keccak256("makeCommitment(string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(string,address,uint256,bytes32)") ^
        keccak256("renew(string,uint256)")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(string,address,uint256,bytes32,address,address)") ^
        keccak256("makeCommitmentWithConfig(string,address,bytes32,address,address)")
    );

    Root root;
    PriceOracle prices;
    uint public minCommitmentAge;
    uint public maxCommitmentAge;

    mapping(bytes32=>uint) public commitments;

    address approverAddress;

    IERC20 private dWebToken;

    uint256 private allowedFeeSlippagePercentage;

    //Wallet where DWEB fees will go
    address private dwebDistributorAddress;
    //Wallet where ETH fees will go
    address payable private companyWallet;

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);

    event DecentraWebDistributorChanged(address indexed dwebDistributorAddress);
    event CompanyWalletChanged(address indexed wallet);

    modifier onlyContract(address account)
    {
        require(account.isContract(), "[Validation] The address does not contain a contract");
        _;
    }

    constructor(Root _root, PriceOracle _prices, IERC20 _dWebToken, address _dwebDistributorAddress, address payable _companyWallet, uint _minCommitmentAge, uint _maxCommitmentAge) {
        require(_maxCommitmentAge > _minCommitmentAge);

        root = _root;
        prices = _prices;
        dWebToken = _dWebToken;
        dwebDistributorAddress = _dwebDistributorAddress;
        companyWallet = _companyWallet;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
        allowedFeeSlippagePercentage = 5;
    }

    // Actual price is returned. Any additional cost/price slippage should be taken care by front end when sending tx
    // returned price is in wei or ERC20 token decimal 
    // duration in seconds
    function rentPrice(string memory name, uint duration, bool isFeeInDWEBToken) view public returns(uint256) {
        bytes32 label = keccak256(bytes(name));
        bytes32 tokenId = keccak256(abi.encodePacked(root.rootNode(), label));
        return prices.price(name, root.nameExpires(uint256(tokenId)), duration, isFeeInDWEBToken, address(dWebToken));
    }

    function valid(string memory name) public pure returns(bool) {
        return name.strlen() >= 3;
    }

    function available(string memory name) public view returns(bool) {
        bytes32 label = keccak256(bytes(name));
        bytes32 tokenId = keccak256(abi.encodePacked(root.rootNode(), label));
        return valid(name) && root.available(uint256(tokenId));
    }

    function makeCommitment(string memory name, address owner, bytes32 secret) pure public returns(bytes32) {
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment, uint8 v, bytes32 r, bytes32 s) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        // name must be approved by approver address
        
        //TODO-release: uncomment below block
        /*
        address signer = ecrecover(commitment, v, r, s);
        require(signer == approverAddress, "commit: invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");
        */
        
        commitments[commitment] = block.timestamp;
    }

    function register(string calldata name, address owner, uint duration, bytes32 secret, bool isFeeInDWEBToken, uint256 fee) external payable {
      registerWithConfig(name, owner, duration, secret, address(0), address(0), isFeeInDWEBToken, fee);
    }

    // fee must be passed in decimal
    function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr, bool isFeeInDWEBToken, uint256 fee) public payable {
        
        // TODO: name has to be TLD. put check for this
        bytes32 commitment = makeCommitmentWithConfig(name, owner, secret, resolver, addr);
        
        _consumeCommitment(name, duration, commitment);

        uint256 cost = rentPrice(name, duration, isFeeInDWEBToken);
        require(msg.value >= cost, "[Validation] Enough ETH not sent");

        bytes32 label = keccak256(bytes(name));
        // The nodehash of this label
        bytes32 tokenId = keccak256(abi.encodePacked(root.rootNode(), label));

        uint expires;
        // TODO-enhancement : skipping setting records for now
        // ---
        // if(resolver != address(0)) {
        //     // Set this contract as the (temporary) owner, giving it
        //     // permission to set up the resolver.
        //     expires = root.register(uint256(tokenId), address(this), duration);

        //     // Set the resolver
        //     root.ens().setResolver(tokenId, resolver);

        //     // Configure the resolver
        //     if (addr != address(0)) {
        //         Resolver(resolver).setAddr(tokenId, addr);
        //     }

        //     // Now transfer full ownership to the expeceted owner
        //     //base.reclaim(tokenId, owner);
            
        //     //base.transferFrom(address(this), owner, tokenId);
        //     // TODO: can we improve below?
        //     root.decentraNameController().decentraName().safeTransferFrom(address(this), owner, uint256(tokenId));
        // } else 
        // ---
        {
            require(addr == address(0));
            expires = root.register(uint256(tokenId), owner, duration);
        }

        

        // Process payment

        if(isFeeInDWEBToken) {
            // TODO-review: do we really need to fail the tx
            uint256 feeDiff = 0;
            if( fee < cost ) {
                feeDiff = cost.sub(fee);
                uint256 feeSlippagePercentage = feeDiff.mul(100).div(cost);
                //will allow if diff is less than 5%
                require(feeSlippagePercentage < allowedFeeSlippagePercentage, "[Validation] Fee (DWEB) is below minimum required fee");
            }
            dWebToken.safeTransferFrom(msg.sender, dwebDistributorAddress, cost);
        } else {
            // TODO-review : we still need to refund right?
            (bool success,) = companyWallet.call{value: cost}("");
            require(success, "[Validation] Transfer of fee failed");

            // Refund any extra payment
            if(msg.value > cost) {
                payable(msg.sender).transfer(msg.value - cost);
            }
        }

        emit NameRegistered(name, label, owner, cost, expires);

    }

    function renew(string calldata name, uint duration, bool isFeeInDWEBToken) external payable {
        // TODO: manage total duration should be between 1 year and 5 years
        // TODO: payment processing in dweb pending
        uint256 cost = rentPrice(name, duration, isFeeInDWEBToken);
        require(msg.value >= cost);

        bytes32 label = keccak256(bytes(name));
        bytes32 tokenId = keccak256(abi.encodePacked(root.rootNode(), label));
        uint expires = root.renew(uint256(tokenId), duration);

        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit NameRenewed(name, label, cost, expires);
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setCommitmentAges(uint _minCommitmentAge, uint _maxCommitmentAge) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);        
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == COMMITMENT_CONTROLLER_ID ||
               interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(string memory name, uint duration, bytes32 commitment) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(name));

        delete(commitments[commitment]);

        require(duration >= MIN_REGISTRATION_DURATION);
        require(duration <= MAX_REGISTRATION_DURATION);
    }

    function setApproverAddress(address _approver) external onlyOwner {
        approverAddress = _approver;
    }

    function setDecentraWebDistributor(address _dwebDistributorAddress) external onlyOwner onlyContract(dwebDistributorAddress) {
        require(
            _dwebDistributorAddress != address(0),
            "[Validation] dwebDistributorAddress is the zero address"
        );
        dwebDistributorAddress = _dwebDistributorAddress;

        emit DecentraWebDistributorChanged(_dwebDistributorAddress);
    }

    function setCompanyWallet(address payable wallet) external onlyOwner {
        require(
            wallet != address(0),
            "[Validation] wallet is the zero address"
        );
        companyWallet = wallet;

        emit CompanyWalletChanged(wallet);
    }
}
