// SPDX-License-Identifier: SimPL-2.0
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

interface qampl_token{
    function rebase() external view;
}

contract rebase_sync{

    address qampl_address = 0xa9ad3421c8953294367D3B2f6efb9229C690Cacb;

    address[] public  qkswap_Pairs;

    constructor() {
    }
    
    
    //传入一个新的token地址，这个地址需要在qkswap里面有交易对
    function add_qkswap_Pair(address new_token) public {

        address Pair_address = IQkswapV2Factory(0x4cB5B19e8316743519072170886355B0e2C717cF).getPair(qampl_address, new_token) ;

        //池子里面需要有大于100qa才sync，避免大量gas消耗
        require(token(qampl_address).balanceOf(Pair_address) > 100*1e18);
        for(uint i;i<qkswap_Pairs.length;i++)
        {
            require(qkswap_Pairs[i] != Pair_address);
        }
        qkswap_Pairs.push(Pair_address);


        //刷新流动池的余额
        IQkswapV2Pair pair = IQkswapV2Pair(Pair_address);
        pair.sync();
    }
    
    //rebase并sycn
    function rebase() public {
        qampl_token(qampl_address).rebase();
        for(uint i;i<qkswap_Pairs.length;i++)
        {
            //刷新流动池的余额
            IQkswapV2Pair pair = IQkswapV2Pair(qkswap_Pairs[i]);
            pair.sync();
        }
    }
    
}