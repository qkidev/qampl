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
contract qampl_new_airdrop is SafeMath{

    address public owner;
    address qampl_address = 0xa9ad3421c8953294367D3B2f6efb9229C690Cacb;
    uint Last_airdrop_time = 0;
    address[] public  qkswap_Pairs;
    uint public require_qampl=2e21;
    address qkswap_pair_quaddress = 0x7439da46526DE466c72E67E26e9aB363d7731B22;
    address QAowner = 0xD4a1a03bEeEAba88EAb481D8632Ac6e803936935;
    constructor() {
        owner = msg.sender;
    }
    //需要qa作者将qa给合约
    //仅容许管理员可以触发空投合约
    function airdrop() public {
        require(block.timestamp - Last_airdrop_time >= 86400);
        require(msg.sender == owner);
        //usdt交易对给额外空投0.2%持有量  
        uint addtional_airdrop_qampl=token(qampl_address).balanceOf(qkswap_pair_quaddress)/830;
            safeTransferFrom(qampl_address,QAowner,qkswap_pair_quaddress,addtional_airdrop_qampl);
         for(uint i;i<qkswap_Pairs.length;i++)
        {
            //给币对空投1%持有量
            uint airdrop_qampl = token(qampl_address).balanceOf(qkswap_Pairs[i])/100;
            safeTransferFrom(qampl_address,QAowner,qkswap_Pairs[i],airdrop_qampl);

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
    
    function setOwner(address payable new_owner) public {
        require(msg.sender == owner);
        owner = new_owner;
    }
     //设置一个值只有池子里的值大于这个值才能加进空投的范围之内
    function set_require_qampl(uint _value) public{
        require(msg.sender == owner);
        require_qampl = _value;
     }
    //传入一个新的token地址，这个地址需要在qkswap里面有交易对
    //添加仅允许管理员，否则返回
    function add_qkswap_Pair(address new_token) public {
        if(msg.sender != owner)revert();
        address Pair_address = IQkswapV2Factory(0x4cB5B19e8316743519072170886355B0e2C717cF).getPair(qampl_address, new_token); 
        require(token(qampl_address).balanceOf(Pair_address) >require_qampl);
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
