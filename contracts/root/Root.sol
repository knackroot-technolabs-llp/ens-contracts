pragma solidity ^0.8.4;

import "../registry/ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Controllable.sol";
import "../decentraname/IDecentraNameController.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract Root is Ownable, Controllable, ERC721Holder {
    bytes32 public constant rootNode = bytes32(0);
    uint public constant GRACE_PERIOD = 90 days;

    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    // bytes4 constant private RECLAIM_ID = bytes4(keccak256("reclaim(uint256,address)"));

    ENS public ens;

    // The dweb NFT token
    IDecentraNameController public decentraNameController;

    // TODO: set expiry of root domain as infinity
    // A map of expiry times
    mapping(uint256=>uint) expiries;

    // TODO: does locked makes sense now?
    mapping(bytes32 => bool) public locked;

    event TLDLocked(bytes32 indexed label);
    event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
    event NameRenewed(uint256 indexed id, uint expires);

    constructor(ENS _ens, IDecentraNameController _decentraNameController) {
        ens = _ens;
        decentraNameController =  _decentraNameController;
    }

    // pure or view methods
    
    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view returns(uint) {
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns(bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    // modifer protected methods

    function setResolver(address resolver) external onlyOwner {
        ens.setResolver(rootNode, resolver);
    }

    function lock(bytes32 label) external onlyOwner {
        emit TLDLocked(label);
        locked[label] = true;
    }

    function setRootDomainOwner() external onlyOwner {
        decentraNameController.mintToken(address(this), uint256(rootNode));
    }

    // TODO: add transfer method to transfer ownership of root node(NFT) in decentraname 

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */

    function register(uint256 id, address owner, uint duration) external onlyController returns(uint) {
        require(available(id));
        require(block.timestamp + duration + GRACE_PERIOD > block.timestamp + GRACE_PERIOD); // Prevent future overflow

        expiries[id] = block.timestamp + duration;
        if(decentraNameController.existsToken(id)) {
            // Name was previously owned, and expired
            decentraNameController.burnToken(id);
        }
        decentraNameController.mintToken(owner, id);

        emit NameRegistered(id, owner, block.timestamp + duration);

        return block.timestamp + duration;
    }

    function renew(uint256 id, uint duration) external onlyController returns(uint) {
        require(expiries[id] + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period
        require(expiries[id] + duration + GRACE_PERIOD > duration + GRACE_PERIOD); // Prevent future overflow

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    // TODO: revisit this. we may not require reclaim as every url is now NFT
    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    // function reclaim(uint256 id, address owner) external override live {
    //     require(decentraNameController.isApprovedOrOwner(msg.sender, id));
    //     ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    // }
}
