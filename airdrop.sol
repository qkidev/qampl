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

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
/**
 * 持有qa账号，给这个合约授权，然后调用空投合约。
 */
contract qampl_airdrop is SafeMath{

    address public owner;
    address qampl_address = 0xa9ad3421c8953294367D3B2f6efb9229C690Cacb;
    uint Last_airdrop_time = 0;

    address[] public  qkswap_Pairs;

    constructor() {
        owner = msg.sender;
    }

    //每个人都可以调用空投方法，但是24小时一次
    //需要管理员授权自己的qa给合约
    function airdrop() public {
        require(block.timestamp - Last_airdrop_time >= 86400);
        for(uint i;i<qkswap_Pairs.length;i++)
        {
            //给币对空投1%持有量
            uint airdrop_qampl = token(qampl_address).balanceOf(qkswap_Pairs[i])/100;
            safeTransferFrom(qampl_address,owner,qkswap_Pairs[i],airdrop_qampl);

            //刷新流动池的余额
            IQkswapV2Pair pair = IQkswapV2Pair(qkswap_Pairs[i]);
            pair.sync();
        }
        Last_airdrop_time = block.timestamp;
    }

    

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    
    //传入一个新的token地址，这个地址需要在qkswap里面有交易对
    function add_qkswap_Pair(address new_token) public {
        if(msg.sender != owner)revert();
        
        address Pair_address = IQkswapV2Factory(0x4cB5B19e8316743519072170886355B0e2C717cF).getPair(qampl_address, new_token) ;

        //池子里面需要有大于10qa才能参与空投
        require(token(qampl_address).balanceOf(Pair_address) > 1e19);
        for(uint i;i<qkswap_Pairs.length;i++)
        {
            require(qkswap_Pairs[i] != Pair_address);
        }
        qkswap_Pairs.push(Pair_address);
        

        //刷新流动池的余额
        IQkswapV2Pair pair = IQkswapV2Pair(Pair_address);
        pair.sync();
    }
    
    function Pair_amount() public view returns (uint amount){
        return qkswap_Pairs.length;
    }
}
