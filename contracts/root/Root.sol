pragma solidity ^0.8.4;

import "../registry/ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Controllable.sol";
import "../dwebtoken/DwebTokenController.sol";

contract Root is Ownable, Controllable {
    bytes32 public constant rootNode = bytes32(0);
    uint public constant GRACE_PERIOD = 90 days;

    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    // bytes4 constant private RECLAIM_ID = bytes4(keccak256("reclaim(uint256,address)"));

    ENS public ens;

    // The dweb NFT token
    DwebTokenController public dwebTokenController;

    // A map of expiry times
    mapping(uint256=>uint) expiries;

    mapping(bytes32 => bool) public locked;

    event TLDLocked(bytes32 indexed label);
    event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
    event NameRenewed(uint256 indexed id, uint expires);

    constructor(ENS _ens, DwebTokenController _dwebTokenController) {
        ens = _ens;
        dwebTokenController = _dwebTokenController;
    }

    function setSubnodeOwner(bytes32 label, address owner)
        external
        onlyController
    {
        require(!locked[label]);
        ens.setSubnodeOwner(rootNode, label, owner);
    }

    function setResolver(address resolver) external onlyOwner {
        ens.setResolver(rootNode, resolver);
    }

    function lock(bytes32 label) external onlyOwner {
        emit TLDLocked(label);
        locked[label] = true;
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view returns(uint) {
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns(bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(uint256 id, address owner, uint duration) external returns(uint) {
      return _register(id, owner, duration, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(uint256 id, address owner, uint duration) external returns(uint) {
      return _register(id, owner, duration, false);
    }

    function _register(uint256 id, address owner, uint duration, bool updateRegistry) internal onlyController returns(uint) {
        require(available(id));
        require(block.timestamp + duration + GRACE_PERIOD > block.timestamp + GRACE_PERIOD); // Prevent future overflow

        expiries[id] = block.timestamp + duration;
        if(dwebTokenController.existsToken(id)) {
            // Name was previously owned, and expired
            dwebTokenController.burnToken(id);
        }
        dwebTokenController.mintTokenForTLD(owner, id);
        if(updateRegistry) {
            ens.setSubnodeOwner(rootNode, bytes32(id), owner);
        }

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
    // TODO: review: removing below methods as it is no logner required. Now ownership is no longer managed in ens but in DwebToken only
    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    // function reclaim(uint256 id, address owner) external override live {
    //     require(dwebTokenController.isApprovedOrOwner(msg.sender, id));
    //     ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    // }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return interfaceID == INTERFACE_META_ID;
    }
}
