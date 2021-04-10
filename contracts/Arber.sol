pragma solidity 0.5.17;

import "./UniswapFlashSwapper.sol";
import "./Libraries.sol";

contract Arber is UniswapFlashSwapper {
    using SafeMath for uint256;

    address private owner;
    //address private constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 UniswapV2Router;
    IUniswapV2Router02 SushiswapV1Router;

    modifier onlyOwner () {
        require(msg.sender == owner, "ONLY OWNER CAN CALL THIS FUNCTION");
        _;
    }

    /*
    * @dev init params
    * */
    constructor (
            address _DAI, address _WETH, 
            IUniswapV2Router02 _uniswapV2Router, 
            IUniswapV2Router02 _sushiswapV1Router
        ) public UniswapFlashSwapper(_DAI, _WETH) {
        owner = msg.sender;

        // init SushiswapV1 and UniswapV2 Router02
        UniswapV2Router = IUniswapV2Router02(address(_uniswapV2Router));
        SushiswapV1Router = IUniswapV2Router02(address(_sushiswapV1Router));
    }

    /*
     * @dev get owner of contract
     * */
    function getOwner() public view returns(address) {
        return owner;
    }

    /*
     * @dev withdraw ETH
     *
     */
    function withdrawETH() public payable onlyOwner {
        require(msg.sender.send(address(this).balance));
    }

    /*
     * @dev withdraw a given token
     * @param address of token to withdraw 
     * */
    function withdrawToken(address token) public payable onlyOwner {
        IERC20 _token = IERC20(token);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }



    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenPay The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @param _userData Data that will be passed to the `execute` function for the user
    // @dev Depending on your use case, you may want to add access controls to this function
    function flashSwap(address _tokenBorrow, uint256 _amount, address _tokenPay, bytes calldata _userData) external onlyOwner {
        // TODO: call data should also include which DEX to use for arbing

        // Start the flash swap
        // This will acuire _amount of the _tokenBorrow token for this contract and then
        // run the `execute` function below
        startSwap(_tokenBorrow, _amount, _tokenPay, _userData);

    }


    // @notice This is where your custom logic goes
    // @dev When this code executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds
    //     at least _amountToRepay of the _tokenPay token
    // @dev Paying back the flash-loan happens automatically for you -- DO NOT pay back the loan in this function
    // @param _tokenBorrow The address of the token you flash-borrowed, address(0) indicates ETH
    // @param _amount The amount of the _tokenBorrow token you borrowed
    // @param _tokenPay The address of the token in which you'll repay the flash-borrow, address(0) indicates ETH
    // @param _amountToRepay The amount of the _tokenPay token that will be auto-removed from this contract to pay back
    //        the flash-borrow when this function finishes executing
    // @param _userData Any data you privided to the flashBorrow function when you called it
    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) internal {
        // execute arb
        // TODO: check for exchange to sell on
        // for now just swap token on Sushi
        uint256 deadline = block.timestamp + 300;
        SushiswapV1Router.swapExactTokensForETH(
            _amount,
            getEstimatedETHForToken(_amount, _tokenBorrow)[0],
            getPathForTokenToETH(_tokenBorrow),
            address(this),
            deadline
        );
    }

    // @notice Simple getter for convenience while testing
    function getBalanceOf(address _input) external view returns (uint) {
        if (_input == address(0)) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }

    /**
     * @dev check ERC20 to ETH conversion rate
     */
    function getEstimatedETHForToken(uint _tokenAmount, address _token) public view returns (uint[] memory) {
        return UniswapV2Router.getAmountsOut(_tokenAmount, getPathForTokenToETH(_token));
    }

    /**
        Using a WETH wrapper to convert ERC20 token back into ETH
     */
     function getPathForTokenToETH(address _token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = SushiswapV1Router.WETH();
        
        return path;
    }

    /**
      * @dev  Using a WETH wrapper here since there are no direct ETH pairs in Uniswap v2
      *  and sushiswap v1 is based on uniswap v2
     */
    function getPathForETHToToken(address _token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = UniswapV2Router.WETH();
        path[1] = _token;
    
        return path;
    }

}