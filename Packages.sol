pragma solidity ^0.5.4;

import "./GoleToken.sol";
import "./Owner.sol";

contract Packages is Owner{
    using SafeMath for uint256;

    uint256 private _templateCount;
    uint256 private _pkgCount;
    address public goleContract;
    GoleToken g;

    mapping (uint256 => bool) public onSale;
    mapping (uint256 => address) public royaltyEarner;
    mapping (uint256 => _Package) public package;
    mapping (address => uint256) public userLevel;
    mapping (address => bool) public onPartTime;
    mapping (uint256 => bool) public expiredPackage;  
    mapping (uint256 => bool) private _markForExpire;
    mapping (uint256 => address) public highestBidder;
    mapping (uint256 => uint256) public highestBid;
    mapping (uint256 => address) public packageOwner;
    mapping (address => uint256) public goleToUnfreeze;
    mapping (uint256 => _Template) public template;
    mapping (uint256 => uint256) public templateId;
    mapping (uint256 => bool) public transferable;
    
    
    
    //reimplementing pkgtype as template
    struct _Template {
        uint256 id;
        string category;
        uint256 stake;
        uint256 reward;
        bool business;
        bool career;
        bool partTime;
        uint256 level;
    }

    // use pkgCount
    struct _Package {
        uint256 id;
        string category;
        string description;
        uint256 stake;
        uint256 reward;
        bool business;
        bool career;
        bool partTime;
        uint256 level;
    }

    // put events in IGole
    event OwnPackage(
        uint256 id,
        string description,
        uint256 stake,
        uint256 reward,
        string pkgType,
        uint256 level,
        address user
    ); 

    event ExpirePackage(
        uint256 id,
        string pkgName,
        uint256 stake,
        uint256 reward,
        string pkgType,
        uint256 level,
        address user
    );

    event SellPackage(
        uint256 id,
        string description,
        uint256 stake,
        uint256 reward,
        string pkgType,
        uint256 level,
        address user
    );

    event UnsoldPackage(
        uint256 id,
        string description,
        uint256 stake,
        uint256 reward,
        string pkgType,
        uint256 level,
        address user
    );

    event ExtendPackage(
        uint256 id,
        string description,
        uint256 stake,
        uint256 reward,
        string pkgType,
        uint256 level,
        address user
    );

    event Bid(
        uint256 id,
        string description,
        uint256 stake,
        uint256 reward,
        string pkgType,
        uint256 level,
        address bidder,
        uint256 bid,
        uint256 fee
    );

    constructor (address _contract) public {
        onPartTime[msg.sender] = false;
        goleContract = _contract;
        g = GoleToken(goleContract);
    }

    function createTemplate(
        string memory _category,
        uint256 _stake,
        uint256 _reward,
        bool _career,
        bool _partTime,
        uint256 _level
    ) public onlyOwner returns (bool) {
        _templateCount = _templateCount.add(1);
        template[_templateCount] = _Template(
            _templateCount,
            _category,
            _stake,
            _reward,
            false, //business
            _career,
            _partTime,
            _level
        );
        return true;
    }

    function createBusinessTemplate(
        string memory _category,
        uint256 _stake1,
        uint256 _stake2,
        uint256 _stake3,
        uint256 _stake4,
        uint256 _reward1,
        uint256 _reward2,
        uint256 _reward3,
        uint256 _reward4
    ) public onlyOwner returns (bool) {
        _templateCount = _templateCount.add(1);
        template[_templateCount] = _Template(
            _templateCount,
            _category,
            _stake1,
            _reward1,
            true, //business
            false, //career
            false, //partTime
            1
        );
        _templateCount = _templateCount.add(1);
        template[_templateCount] = _Template(
            _templateCount,
            _cateegory,
            _stake2,
            _reward2,
            true, //business
            false, //career
            false, //partTime
            2
        );
        _templateCount = _templateCount.add(1);
        template[_templateCount] = _Template(
            _templateCount,
            _category,
            _stake3,
            _reward3,
            true, //business
            false, //career
            false, //partTime
            3
        );
        _templateCount = _templateCount.add(1);
        template[_templateCount] = _Template(
            _templateCount,
            _category,
            _stake4,
            _reward4,
            true, //business
            false, //career
            false, //partTime
            4
        );

        return true;
    }

    // admin to create the package
    function createPackage(
        string memory _category,
        string memory _description,
        uint256 _stake,
        uint256 _reward,
        bool _business,
        bool _career,
        bool _partTime,
        uint256 _level
    ) internal returns (uint256){
        _pkgCount = _pkgCount.add(1);
        package[_pkgCount] = _Package(
            _pkgCount,
            _category,
            _description,
            _stake,
            _reward,
            _business,
            _career,
            _partTime,
            _level
        );

        string packageType = getPackageType(_pkgCount);
        if(packageType != 'Business') {
            transferable[_pkgCount] = false;
        } else {
            transferable[_pkgCount] = true;
        }

        return _pkgCount;
    }

    function getPackageType(uint256 _id) public view returns (string memory) {
        _Package storage _package = package[_id];

        string memory packageType;
        if (_package.career) {
            packageType = 'Career';
        } else if (_package.partTime) {
            packageType = 'Part Time';
        } else {
            packageType = 'Business';
        }

        return packageType;
    }

    function newPartTime(string memory _description, uint256 _templateId) public returns (bool) {
        require(_templateId > 0 && _templateId <= _templateCount);
        require(userLevel[msg.sender] == 1);
        require(!onPartTime[msg.sender]);       
        
        _Template storage _template = template[_templateId];
        require(g.freezeGole(_template.stake));
        uint256 packageId = createPackage(
            _description,
            _template.stake,
            _template.reward,
            false, //business
            false, //career
            true, //partTime
            _template.level  
        );
        packageOwner[packageId] = msg.sender;
        onPartTime[msg.sender] = true;
        transferable[packageId] = false;

        emit OwnPackage(
            packageId,
            _description,
            _template.stake,
            _template.reward,
            'Part Time',
            _template.level,
            msg.sender    
        );   

        return true;
    }

    function newCareer(string memory _description, uint256 _templateId) public returns (bool) {
        require(_templateId > 0 && _templateId <= _templateCount);
        require(!onPartTime[msg.sender]);       
        
        _Template storage _template = template[_templateId];

        uint256 checkLevel = userLevel[msg.sender].add(1);

        require(_template.level == checkLevel || userLevel[msg.sender] > 3);
        if(userLevel[msg.sender] > 3){
            require(_template.level > 2);
        }  
        require(g.freezeGole(_template.stake));
        uint256 packageId = createPackage(
            _description,
            _template.stake,
            _template.reward,
            false, //business
            true, //career
            false, //partTime
            _template.level  
        );
        packageOwner[packageId] = msg.sender;
        if(userLevel[msg.sender] < _template.level) {
            userLevel[msg.sender] = userLevel[msg.sender].add(1);
        } else {
            userLevel[msg.sender] = _template.level;
        }
        transferable[packageId] = false

        emit OwnPackage(
            packageId,
            _description,
            _template.stake,
            _template.reward,
            'Career',
            _template.level,
            msg.sender    
        );   

        return true;
    }

    function createBusiness(string memory _description, uint256 _templateId) public returns (bool) {
        require(_templateId > 0 && _templateId <= _templateCount);
        // only level 4 can create business
        require(userLevel[msg.sender] > 3);
        _Template storage _template = template[_templateId];
        require(g.freezeGole(_template.stake));
        uint256 packageId = createPackage(
            _description,
            _template.stake,
            _template.reward,
            true, //business
            false, //career
            false, //partTime
            _template.level  
        );
        templateId[packageId] = _templateId;
        packageOwner[packageId] = msg.sender;

        emit OwnPackage(
            packageId,
            _description,
            _template.stake,
            _template.reward,
            'Business',
            _template.level,
            msg.sender    
        );

        return true;
    }

    //put one for admin to create and sell to marketplace`

    function upgradeBusiness(uint256 _id) public returns (bool) {
        require(_id > 0 && _id <= _pkgCount);
        require(packageOwner[_id] == msg.sender);
        require(!onSale[_id]);
        require(!expiredPackage[_id]);
        _Package storage _package = package[_id];
        require(_package.level < 4);
        _Template storage _template = template[templateId[_id].add(1)];

        // will need to mark the previous one for expire somehow.
        _markForExpire[_id] = true;

        uint256 packageId = createPackage(
            _package.description,
            _template.stake,
            _template.reward,
            true, //business
            false, //career
            false, //partTime
            _template.level
        );

        packageOwner[packageId] = msg.sender;

        emit OwnPackage(
            packageId,
            _package.description,
            _template.stake,
            _template.reward,
            'Business',
            _template.level,
            msg.sender    
        );

        return true;
    }

    function markForExpire(uint256 _id) public view onlyOwner returns (bool) {
        return _markForExpire[_id];
    }

    function expirePackage(uint256 _id) public onlyOwner {
        require(_id > 0 && _id <= _pkgCount);
        require(!expiredPackage[_id]);
        // don't expire while it is still on the selling block
        require(!onSale[_id]);
        _Package storage _package = package[_id];
        g.freeGole(packageOwner[_id], _package.stake);
        expiredPackage[_id] = true;

        if(_package.partTime) {
            onPartTime[packageOwner[_id]] = false;
        }

        string memory packageType = getPackageType(_id);

        emit ExpirePackage(
            _id,
            _package.description,
            _package.stake,
            _package.reward,
            packageType,
            _package.level,
            packageOwner[_id]
        ); 
    }

    // owner puts package on the Marketplace
    function sellPackage(uint256 _id) public returns(bool) {
        require(_id > 0 && _id <= _pkgCount);
        require(!expiredPackage[_id]);
        // cannot sell a package already on sale
        require(!onSale[_id]);
        // only owner can put package on sale
        require(packageOwner[_id] == msg.sender);        
        _Package storage _package = package[_id];
        require(_package.business);
        onSale[_id] = true;
        highestBidder[_id] = msg.sender;
        highestBid[_id] = _package.stake;

        string memory packageType = getPackageType(_id);

        emit SellPackage(
            _id,
            _package.description,
            _package.stake,
            _package.reward,
            packageType,
            _package.level,
            packageOwner[_id]
        ); 

        return true;
    }

    function _getSalesFee(uint256 _amount) private pure returns(uint256) {
        _amount = _amount.mul(5).div(100);
        return _amount;
    }

    function bidPackage(uint256 _id, uint256 _offer) public returns(bool) {
        // only level 2 onwards can bid
        require(userLevel[msg.sender] > 1);
        require(_id > 0 && _id <= _pkgCount);
        require(!expiredPackage[_id]);
        require(onSale[_id]);
        // can't bid on own package
        require(packageOwner[_id] != msg.sender);
        require(_offer > highestBid[_id]);
        require(_offer.add(_getSalesFee(_offer)) <= g.availableGole(msg.sender));
        // after checks, freeze highest bidder's Gole plus fee.
        g.freezeGole(_offer.add(_getSalesFee(_offer)));
        // free up previous highest bidder's Gole. this will fail because not admin.how?
        goleToUnfreeze[highestBidder[_id]] = highestBid[_id];
        // change highest bidder to current user
        highestBidder[_id] = msg.sender;
        highestBid[_id] = _offer;

        _Package storage _package = package[_id];
        string memory packageType = getPackageType(_id);

        emit Bid(
            _id,
            _package.description,
            _package.stake,
            _package.reward,
            packageType,
            _package.level,
            msg.sender,
            _offer,
            _getSalesFee(_offer)
        );

        return true;
    } 

    function endSale(uint256 _id) public onlyOwner {
        onSale[_id] = false;
    }

    function unfreezeGole(address _user) public onlyOwner returns (bool) {
        require(_user != address(0));
        g.freeGole(_user, goleToUnfreeze[_user]);
        goleToUnfreeze[_user] = 0;
        return true;
    }
    
    // upon successful bid of a package. must be signed by admin.
    function transferPackage(uint256 _id) public onlyOwner returns(bool) {
        require(_id > 0 && _id <= _pkgCount);
        require(!expiredPackage[_id]);
        require(onSale[_id]);

        //only buyer and owner cannot be the same person
        require(highestBidder[_id] != packageOwner[_id]);

        _Package storage _package = package[_id];

        uint256 profitFee = highestBid[_id].sub(_package.stake);
        //free up buyer's Gole to pay
        g.freeGole(highestBidder[_id], profitFee);

        //free up seller's Gole
        g.freeGole(packageOwner[_id], _package.stake);

        // allow admin to spend gole
        g.adminIncreaseAllowance(highestBidder[_id], owner(), profitFee);
        
        //pay admin's fee
        g.transferFrom(highestBidder[_id], owner(), _getSalesFee(_package.stake));

        //pay seller's profit
        g.transferFrom(highestBidder[_id], packageOwner[_id], profitFee.sub(_getSalesFee(_package.stake)));

        //set previous owner as royaltyEarner
        royaltyEarner[_id] = packageOwner[_id]; 

        //transfer ownership
        packageOwner[_id] = highestBidder[_id];

        //no longer on sale
        onSale[_id] = false;     

        emit OwnPackage(
            _id,
            _package.description,
            _package.stake,
            _package.reward,
            'Business',
            _package.level,
            packageOwner[_id]    
        );   

        return true;
    }

    function unsoldPackage(uint256 _id) public onlyOwner {
        require(_id > 0 && _id <= _pkgCount);
        require(!expiredPackage[_id]);
        require(onSale[_id]);

        _Package storage _package = package[_id];
        require(highestBidder[_id] == packageOwner[_id]);

        onSale[_id] = false;

        emit UnsoldPackage(
            _id,
            _package.description,
            _package.stake,
            _package.reward,
            'Business',
            _package.level,
            packageOwner[_id]    
        );
    }

    function extendPackage(uint256 _id) public returns (bool) {
        require(_id > 0 && _id <= _pkgCount);
        require(!expiredPackage[_id]);
        require(packageOwner[_id] == msg.sender);
        _Package storage _package = package[_id];
        // can't extend part time packages
        require(!_package.partTime);
        g.transfer(owner, _getSalesFee(_package.stake));

        string memory packageType = getPackageType(_id);

        emit ExtendPackage(
            _id,
            _package.description,
            _package.stake,
            _package.reward,
            packageType,
            _package.level,
            packageOwner[_id]    
        );

        return true;
    }
}

