pragma solidity ^0.5.4;
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Authorized.sol";

contract GoleToken is ERC20, ERC20Detailed, Authorized {
    using SafeMath for uint256;

    mapping (address => uint) private _frozenGole;
    uint256 private _fee;
    bool private _onFee;

    event FrozenGole(address user, uint256 amount, uint256 frozenAmount, uint256 availableBalance);
    event FreedGole(address user, uint256 amount, uint256 frozenAmount, uint256 availableBalance);

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balanceOf(msg.sender).sub(frozenGole(msg.sender)));
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balanceOf(msg.sender).sub(frozenGole(msg.sender)));
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowance(sender,msg.sender).sub(amount));
        return true;
    }

    function frozenGole(address user) public view returns (uint256) {
        require(user != address(0));
        return _frozenGole[user];
    }

    function freezeGole(uint256 amount) public returns (bool) {
        _frozenGole[msg.sender] = _frozenGole[msg.sender].add(amount);

        emit FrozenGole(
            msg.sender,
            amount,
            frozenGole(msg.sender),
            availableGole(msg.sender)
        );

        return true;
    }

    function freeGole(address user, uint256 amount) public onlyOwner returns (bool) {
        require(user != address(0));
        require(amount <= frozenGole(user));
        _frozenGole[user] = _frozenGole[user].sub(amount);

        emit FreedGole(
            msg.sender,
            amount,
            frozenGole(msg.sender),
            availableGole(msg.sender)
        );

        return true;
    }

    function availableGole(address user) public view returns (uint256) {
        require(user != address(0));
        return balanceOf(user).sub(frozenGole(user));
    }

    function fee() public view onlyOwner returns(uint256) {
        return _fee;
    }

    // to be divided by 100, starting from 1 as 0.1%
    function setFee(uint256 _percentage) public onlyOwner returns (uint256) {
        _fee = _percentage;
        return _fee;
    }


    function claim(address _user, uint256 _earnings) public onlyOwner returns (bool) {
        require(_user != address(0));
        uint256 adminFee = _earnings.mul(fee()).div(1000);

        transfer(_user, _earnings.sub(adminFee));

        return true;
    }

    function mint(address _user, uint256 _amount) public onlyOwner returns (bool) {
        _mint(_user, _amount);
        return true;
    }

    function burn(address _user, uint256 _amount) public onlyOwner returns (bool) {
        _burn(_user, _amount);
        return true;
    }

    function adminIncreaseAllowance(address owner, address spender, uint256 addedValue) public onlyOwner returns (bool) {
        _approve(owner, spender, allowance(owner, spender).add(addedValue));
        return true;
    }

    function adminDecreaseAllowance(address owner, address spender, uint256 subtractedValue) public onlyOwner returns (bool) {
        _approve(owner, spender, allowance(owner, spender).sub(subtractedValue));
        return true;
    }

}
