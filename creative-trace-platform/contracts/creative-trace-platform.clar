;; CreativeTrace - Provenance-Powered Creative Economy Platform
;; A smart contract for authenticating, trading, and monetizing creative works

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-transfer-failed (err u105))
(define-constant err-invalid-percentage (err u106))

;; Data Variables
(define-data-var next-work-id uint u1)
(define-data-var next-creator-id uint u1)
(define-data-var platform-fee-percentage uint u250) ;; 2.5% (basis points)

;; Data Maps

;; Creator Registry
(define-map creators
    principal
    {
        creator-id: uint,
        reputation-score: uint,
        total-works: uint,
        verified: bool,
        registration-block: uint
    }
)

;; Creative Works with Provenance Data
(define-map creative-works
    uint ;; work-id
    {
        creator: principal,
        title: (string-ascii 100),
        provenance-hash: (buff 32), ;; Hash of IoT sensor data
        creation-timestamp: uint,
        authenticity-score: uint,
        royalty-percentage: uint, ;; basis points (e.g., 1000 = 10%)
        is-active: bool,
        total-revenue: uint,
        edition-size: uint,
        minted-editions: uint
    }
)

;; NFT Ownership tracking
(define-map work-ownership
    {work-id: uint, edition: uint}
    {
        owner: principal,
        purchase-price: uint,
        purchase-block: uint
    }
)

;; Collaborative Works - Multiple creators
(define-map collaborators
    {work-id: uint, collaborator: principal}
    {
        contribution-percentage: uint, ;; basis points
        role: (string-ascii 50)
    }
)

;; Reputation Staking
(define-map reputation-stakes
    principal
    uint ;; staked reputation tokens
)

;; Market Analytics Data
(define-map work-analytics
    uint ;; work-id
    {
        engagement-score: uint,
        social-sentiment: uint,
        cultural-impact: uint,
        trend-score: uint,
        last-updated: uint
    }
)

;; Read-only Functions

(define-read-only (get-creator (creator-address principal))
    (map-get? creators creator-address)
)

(define-read-only (get-creative-work (work-id uint))
    (map-get? creative-works work-id)
)

(define-read-only (get-work-owner (work-id uint) (edition uint))
    (map-get? work-ownership {work-id: work-id, edition: edition})
)

(define-read-only (get-collaborator (work-id uint) (collaborator principal))
    (map-get? collaborators {work-id: work-id, collaborator: collaborator})
)

(define-read-only (get-work-analytics (work-id uint))
    (map-get? work-analytics work-id)
)

(define-read-only (get-platform-fee)
    (var-get platform-fee-percentage)
)

(define-read-only (get-reputation-stake (staker principal))
    (default-to u0 (map-get? reputation-stakes staker))
)

;; Public Functions

;; Register as a Creator
(define-public (register-creator)
    (let
        (
            (caller tx-sender)
            (new-id (var-get next-creator-id))
        )
        (asserts! (is-none (map-get? creators caller)) err-already-exists)
        (map-set creators caller {
            creator-id: new-id,
            reputation-score: u100, ;; starting reputation
            total-works: u0,
            verified: false,
            registration-block: block-height
        })
        (var-set next-creator-id (+ new-id u1))
        (ok new-id)
    )
)

;; Verify Creator (only contract owner can verify)
(define-public (verify-creator (creator-address principal))
    (let
        (
            (creator-data (unwrap! (map-get? creators creator-address) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set creators creator-address
            (merge creator-data {verified: true})
        )
        (ok true)
    )
)

;; Create a New Creative Work with Provenance
(define-public (create-work 
    (title (string-ascii 100))
    (provenance-hash (buff 32))
    (authenticity-score uint)
    (royalty-percentage uint)
    (edition-size uint)
)
    (let
        (
            (caller tx-sender)
            (work-id (var-get next-work-id))
            (creator-data (unwrap! (map-get? creators caller) err-not-found))
        )
        (asserts! (<= royalty-percentage u10000) err-invalid-percentage) ;; max 100%
        (asserts! (> edition-size u0) err-invalid-amount)
        
        ;; Create the work
        (map-set creative-works work-id {
            creator: caller,
            title: title,
            provenance-hash: provenance-hash,
            creation-timestamp: block-height,
            authenticity-score: authenticity-score,
            royalty-percentage: royalty-percentage,
            is-active: true,
            total-revenue: u0,
            edition-size: edition-size,
            minted-editions: u0
        })
        
        ;; Initialize analytics
        (map-set work-analytics work-id {
            engagement-score: u0,
            social-sentiment: u0,
            cultural-impact: u0,
            trend-score: u0,
            last-updated: block-height
        })
        
        ;; Update creator stats
        (map-set creators caller
            (merge creator-data {total-works: (+ (get total-works creator-data) u1)})
        )
        
        (var-set next-work-id (+ work-id u1))
        (ok work-id)
    )
)

;; Add Collaborator to a Work
(define-public (add-collaborator 
    (work-id uint)
    (collaborator-address principal)
    (contribution-percentage uint)
    (role (string-ascii 50))
)
    (let
        (
            (work-data (unwrap! (map-get? creative-works work-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator work-data)) err-unauthorized)
        (asserts! (<= contribution-percentage u10000) err-invalid-percentage)
        
        (map-set collaborators 
            {work-id: work-id, collaborator: collaborator-address}
            {
                contribution-percentage: contribution-percentage,
                role: role
            }
        )
        (ok true)
    )
)

;; Mint Edition (Purchase Work)
(define-public (mint-edition (work-id uint) (price uint))
    (let
        (
            (work-data (unwrap! (map-get? creative-works work-id) err-not-found))
            (creator (get creator work-data))
            (current-edition (+ (get minted-editions work-data) u1))
            (royalty-amount (/ (* price (get royalty-percentage work-data)) u10000))
            (platform-fee (/ (* price (var-get platform-fee-percentage)) u10000))
            (creator-amount (- (- price royalty-amount) platform-fee))
        )
        (asserts! (get is-active work-data) err-unauthorized)
        (asserts! (<= current-edition (get edition-size work-data)) err-invalid-amount)
        (asserts! (> price u0) err-invalid-amount)
        
        ;; Transfer payment to creator
        (unwrap! (stx-transfer? creator-amount tx-sender creator) err-transfer-failed)
        
        ;; Transfer platform fee
        (unwrap! (stx-transfer? platform-fee tx-sender contract-owner) err-transfer-failed)
        
        ;; Record ownership
        (map-set work-ownership 
            {work-id: work-id, edition: current-edition}
            {
                owner: tx-sender,
                purchase-price: price,
                purchase-block: block-height
            }
        )
        
        ;; Update work stats
        (map-set creative-works work-id
            (merge work-data {
                minted-editions: current-edition,
                total-revenue: (+ (get total-revenue work-data) price)
            })
        )
        
        (ok current-edition)
    )
)

;; Transfer Ownership
(define-public (transfer-ownership 
    (work-id uint)
    (edition uint)
    (new-owner principal)
    (sale-price uint)
)
    (let
        (
            (ownership-data (unwrap! (map-get? work-ownership {work-id: work-id, edition: edition}) err-not-found))
            (work-data (unwrap! (map-get? creative-works work-id) err-not-found))
            (creator (get creator work-data))
            (royalty-amount (/ (* sale-price (get royalty-percentage work-data)) u10000))
            (seller-amount (- sale-price royalty-amount))
        )
        (asserts! (is-eq tx-sender (get owner ownership-data)) err-unauthorized)
        (asserts! (> sale-price u0) err-invalid-amount)
        
        ;; Transfer payment from buyer to seller
        (unwrap! (stx-transfer? seller-amount new-owner tx-sender) err-transfer-failed)
        
        ;; Transfer royalty to creator
        (unwrap! (stx-transfer? royalty-amount new-owner creator) err-transfer-failed)
        
        ;; Update ownership record
        (map-set work-ownership 
            {work-id: work-id, edition: edition}
            {
                owner: new-owner,
                purchase-price: sale-price,
                purchase-block: block-height
            }
        )
        
        ;; Update work revenue
        (map-set creative-works work-id
            (merge work-data {
                total-revenue: (+ (get total-revenue work-data) sale-price)
            })
        )
        
        (ok true)
    )
)

;; Stake Reputation Tokens
(define-public (stake-reputation (amount uint))
    (let
        (
            (current-stake (get-reputation-stake tx-sender))
            (creator-data (unwrap! (map-get? creators tx-sender) err-not-found))
        )
        (asserts! (>= (get reputation-score creator-data) amount) err-invalid-amount)
        (map-set reputation-stakes tx-sender (+ current-stake amount))
        (ok true)
    )
)

;; Update Work Analytics (restricted to contract owner or verified validators)
(define-public (update-analytics 
    (work-id uint)
    (engagement-score uint)
    (social-sentiment uint)
    (cultural-impact uint)
    (trend-score uint)
)
    (let
        (
            (work-data (unwrap! (map-get? creative-works work-id) err-not-found))
        )
        ;; In production, add validator verification here
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        
        (map-set work-analytics work-id {
            engagement-score: engagement-score,
            social-sentiment: social-sentiment,
            cultural-impact: cultural-impact,
            trend-score: trend-score,
            last-updated: block-height
        })
        (ok true)
    )
)

;; Increase Creator Reputation (contract owner only)
(define-public (increase-reputation (creator-address principal) (amount uint))
    (let
        (
            (creator-data (unwrap! (map-get? creators creator-address) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set creators creator-address
            (merge creator-data {
                reputation-score: (+ (get reputation-score creator-data) amount)
            })
        )
        (ok true)
    )
)

;; Set Platform Fee (contract owner only)
(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u1000) err-invalid-percentage) ;; max 10%
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

;; Deactivate Work (creator only)
(define-public (deactivate-work (work-id uint))
    (let
        (
            (work-data (unwrap! (map-get? creative-works work-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator work-data)) err-unauthorized)
        (map-set creative-works work-id
            (merge work-data {is-active: false})
        )
        (ok true)
    )
)
