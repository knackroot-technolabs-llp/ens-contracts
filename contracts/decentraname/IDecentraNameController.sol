pragma solidity >=0.8.4;


interface IDecentraNameController {

    function ownerOf(uint256 tokenId) external view returns (address);

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    function existsToken(uint256 tokenId) external view returns (bool);

    function burnToken(uint256 tokenId) external;

    function mintToken(address owner, uint256 id) external;

    function transferToken(address to, uint256 id, uint8 v, bytes32 r, bytes32 s, address sender) external;
}