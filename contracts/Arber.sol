pragma solidity 0.5.17;

import "./UniswapFlashSwapper.sol";

contract Arber is UniswapFlashSwapper {

    address private owner;

    modifier onlyOwner () {
        require(msg.sender == owner, "ONLY OWNER CAN CALL THIS FUNCTION");
        _;
    }

    constructor (address _DAI, address _WETH) public UniswapFlashSwapper(_DAI, _WETH) {
        owner = msg.sender;
    }

    /*
     * @dev get owner of contract
     * */
    function getOwner() public view returns(address) {
        return this.owner;
    }

}