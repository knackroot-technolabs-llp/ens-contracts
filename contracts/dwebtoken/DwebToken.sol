pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DwebToken is ERC721, Ownable {

    bytes4 constant private INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant private ERC721_ID = bytes4(
        keccak256("balanceOf(address)") ^
        keccak256("ownerOf(uint256)") ^
        keccak256("approve(address,uint256)") ^
        keccak256("getApproved(uint256)") ^
        keccak256("setApprovalForAll(address,bool)") ^
        keccak256("isApprovedForAll(address,address)") ^
        keccak256("transferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256,bytes)")
    );

    // TODO: token name and description
    constructor() ERC721("","") {
        // TODO: is it ok to mint in constructor
        // setting owner of root(0x0)
        _safeMint(msg.sender, 0x0);
    }

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override(ERC721) returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view virtual override(ERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(address spender, uint256 tokenId) public view virtual returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     * @param tokenId uint256 ID of the token
     * @return * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function existsToken(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * @param tokenId uint256 ID of the token
     * @return * Destroys tokenId. 
     */
    function burnToken(uint256 tokenId) public virtual onlyOwner returns (bool) {
        return _burn(tokenId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     * @param owner owner of the token to be set after mint
     * @param id uint256 ID of the token
     */
    function mintToken(address owner, uint256 id) public virtual onlyOwner {
        _safeMint(owner, id);
    }

    /**
     * @dev Transfers `tokenId` to `to`.
     * @param to transfer token to this address
     * @param id uint256 ID of the token
     */
    function transferToken(address to, uint256 id) public virtual onlyOwner{
        address from = super.ownerOf(id);
        safeTransferFrom(from, to, id);
    }

    function supportsInterface(bytes4 interfaceID) public override(ERC721) view returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == ERC721_ID;
    }
}
