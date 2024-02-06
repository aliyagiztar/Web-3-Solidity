// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    // Sahibi tanımlama
    address public owner;

    // Teklif sayısını tutacak sayaç
    uint256 private counter;

    // Teklifler için yapı
    struct Proposal {
        string title; // Teklifin başlığı
        string description; // Teklifin açıklaması
        uint256 approve; // Onay oy sayısı
        uint256 reject; // Red oy sayısı
        uint256 pass; // Geç oy sayısı
        uint256 total_vote_to_end; // Oy limitine ulaşıldığında teklifin sonlanması
        bool current_state; // Teklifin şu anki durumu, başarılı olup olmadığı
        bool is_active; // Diğer kullanıcıların oy kullanabilme durumu
    }

    // Teklif geçmişi için mapping
    mapping(uint256 => Proposal) public proposal_history;

    // Oy kullanan adresleri tutacak dizi
    mapping(address => uint256) public lastVotedProposal;

    // Yapıcı fonksiyon
    constructor() {
        owner = msg.sender;
    }

    // Sadece sahibin erişebileceği işlemler için modifikatör
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this.");
        _;
    }

    // Aktif teklifler için modifikatör
    modifier active(uint256 proposalId) {
        require(proposal_history[proposalId].is_active, "The proposal is not active.");
        _;
    }

    // Oy kullanmamış kullanıcılar için modifikatör
    modifier newVoter(uint256 proposalId) {
        require(lastVotedProposal[msg.sender] < proposalId, "Address has already voted on this proposal.");
        _;
    }

    // Yeni sahip atama fonksiyonu
    function setOwner(address new_owner) external onlyOwner {
        owner = new_owner;
    }

    // Teklif oluşturma fonksiyonu
    function create(string calldata _title, string calldata _description, uint256 _total_vote_to_end) external onlyOwner {
        counter += 1;
        proposal_history[counter] = Proposal({
            title: _title,
            description: _description,
            approve: 0,
            reject: 0,
            pass: 0,
            total_vote_to_end: _total_vote_to_end,
            current_state: false,
            is_active: true
        });
    }

    // Oy verme fonksiyonu
    function vote(uint256 proposalId, uint8 choice) external active(proposalId) newVoter(proposalId) {
        Proposal storage proposal = proposal_history[proposalId];
        require(choice <= 2, "Invalid choice.");
        
        lastVotedProposal[msg.sender] = proposalId;

        if (choice == 1) {
            proposal.approve += 1;
        } else if (choice == 2) {
            proposal.reject += 1;
        } else {
            proposal.pass += 1;
        }

        uint256 total_vote = proposal.approve + proposal.reject + proposal.pass;
        if (total_vote >= proposal.total_vote_to_end) {
            proposal.is_active = false;
            proposal.current_state = calculateCurrentState(proposalId);
        }
    }

    // Teklif durumunu hesaplama fonksiyonu
    function calculateCurrentState(uint256 proposalId) private view returns(bool) {
        Proposal storage proposal = proposal_history[proposalId];
        return proposal.approve > (proposal.reject + (proposal.pass / 2));
    }

    // Oy kullanıp kullanmadığını kontrol etme fonksiyonu
    function isVoted(uint256 proposalId, address _address) public view returns (bool) {
        return lastVotedProposal[_address] >= proposalId;
    }

    // Şu anki teklifi getirme fonksiyonu
    function getCurrentProposal() external view returns (Proposal memory) {
        return proposal_history[counter];
    }

    // Belirli bir teklifi getirme fonksiyonu
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposal_history[proposalId];
    }
}
