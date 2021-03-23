pragma solidity  ^0.7.6;

interface IQkswapV2Pair {
    function sync() external;
}
interface  token {
    function balanceOf(address owner) external view returns (uint);
}
interface IQkswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract qa_sync{

    address qampl_address = 0xa9ad3421c8953294367D3B2f6efb9229C690Cacb;

    address[] public  qkswap_Pairs;

    constructor() {
    }
    
    
    //传入一个新的token地址，这个地址需要在qkswap里面有交易对
    function add_qkswap_Pair(address new_token) public {

        address Pair_address = IQkswapV2Factory(0x4cB5B19e8316743519072170886355B0e2C717cF).getPair(qampl_address, new_token) ;
        for(uint i;i<qkswap_Pairs.length;i++)
        {
            require(qkswap_Pairs[i] != Pair_address);
        }
        qkswap_Pairs.push(Pair_address);
        //刷新流动池的余额
        IQkswapV2Pair pair = IQkswapV2Pair(Pair_address);
        pair.sync();
    }
}
