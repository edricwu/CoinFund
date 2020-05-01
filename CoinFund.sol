pragma solidity ^0.4.25;

contract Campaign{
    
    struct Owner{
        address addr;
        string name;
        string email;
    }
    
    struct Backer{
        string name;
        string email;
        uint amount;
    }
    
    struct Info{
        address addr;
        string title;
        string description;
        uint target;
        uint monthly;
        uint balance;
        uint withdrawn;
        uint start;
        uint end;
    }
    
    uint public last_released;
    bool public successful;
    bool lock;
    
    Owner public owner;
    mapping (address => Backer) backer_info;
    address[] public backers;
    Info public info;
    
    constructor(string _name, string _email, string _title, string _description, uint _target, uint _monthly, uint _start, uint _end) public{
        owner = Owner(msg.sender, _name, _email);
        info = Info(address(this), _title, _description, _target, _monthly, 0, 0, _start, _end);
    }

    function backCampaign(string _name, string _email) public payable{
        require (msg.sender != owner.addr);
        require (now >= info.start && now <= info.end, "Campaign has not started or has ended!");
        uint _amount = msg.value;
        info.balance += _amount;
        if (backer_info[msg.sender].amount == 0){
            backer_info[msg.sender] = Backer(_name, _email, _amount);
            backers.push(msg.sender);
        }
        else{
            backer_info[msg.sender].amount += _amount;
        }
    }
    
    function getBackerInfo(address user) public view returns(string, string, uint){
        return (backer_info[user].name, backer_info[user].email, backer_info[user].amount);
    }
    
    function releaseFund() public returns(bool){
        require (now >= info.end, "The campaign is still ongoing!");
        require (!successful, "Fund has been released!");
        require (msg.sender == owner.addr || backer_info[msg.sender].amount != 0, "Not authorized");

        // require (!lock);
        // lock = true;

        last_released = now;
        if (address(this).balance < info.target){
            for (uint i=0; i<backers.length; i++) {
                address backer_addr = backers[i];
                uint amount = backer_info[backer_addr].amount;
                if (amount != 0){
                    backer_info[backer_addr].amount = 0;
                    assert(backer_addr.call.value(amount)());
                    info.balance -= amount;
                }    
            }
        }
        else{
            successful = true;
            assert(owner.addr.call.value(info.monthly)());
            info.balance -= info.monthly;
            info.withdrawn += info.monthly;
        }

        // lock = false;

        return successful;
    }

    function getBackers() public view returns(address[]){
        return backers;
    }

    function releaseMonthly() public{
        require (msg.sender == owner.addr);
        require (successful, "The campaign is still ongoing or is unsuccessful!");
        require (now - last_released >= 30 seconds, "Last release is less than 1 month!");
        uint amount = info.monthly;
        if (address(this).balance < info.monthly){
            amount = address(this).balance;
        }
        last_released = now;
        assert(owner.addr.call.value(amount)());
        info.balance -= amount;
        info.withdrawn += amount;
    }
}