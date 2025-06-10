;; Carbon Offset Tokenization Contract
;; A blockchain-based system for tokenizing and trading carbon offset credits

;; Define the carbon offset token
(define-fungible-token carbon-offset-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-project-not-found (err u103))
(define-constant err-insufficient-credits (err u104))
(define-constant err-invalid-project-data (err u105))

;; Token info
(define-data-var token-name (string-ascii 32) "Carbon Offset Token")
(define-data-var token-symbol (string-ascii 10) "COT")
(define-data-var token-decimals uint u6)
(define-data-var total-supply uint u0)

;; Project tracking
(define-map carbon-projects
  uint ;; project-id
  {
    name: (string-ascii 64),
    location: (string-ascii 64),
    project-type: (string-ascii 32), ;; e.g., "Forest", "Solar", "Wind"
    verified-by: (string-ascii 64),
    total-credits: uint, ;; Total CO2 tonnes offset (in micro tonnes)
    available-credits: uint,
    price-per-credit: uint, ;; Price in microSTX per micro tonne
    created-at: uint,
    is-active: bool
  })

(define-map user-credits principal uint)
(define-map project-purchases 
  {project-id: uint, purchaser: principal}
  uint) ;; amount purchased

(define-data-var next-project-id uint u1)
(define-data-var total-projects uint u0)
(define-data-var total-credits-retired uint u0)

;; Function 1: Register Carbon Project
;; Allows verified organizations to register carbon offset projects
(define-public (register-carbon-project
    (name (string-ascii 64))
    (location (string-ascii 64))
    (project-type (string-ascii 32))
    (verified-by (string-ascii 64))
    (total-credits uint)
    (price-per-credit uint))
  (let ((project-id (var-get next-project-id)))
    (begin
      ;; Only contract owner can register projects (acting as verification authority)
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      
      ;; Validate input data
      (asserts! (> (len name) u0) err-invalid-project-data)
      (asserts! (> (len location) u0) err-invalid-project-data)
      (asserts! (> (len project-type) u0) err-invalid-project-data)
      (asserts! (> (len verified-by) u0) err-invalid-project-data)
      (asserts! (> total-credits u0) err-invalid-amount)
      (asserts! (> price-per-credit u0) err-invalid-amount)
      
      ;; Register the carbon project
      (map-set carbon-projects project-id {
        name: name,
        location: location,
        project-type: project-type,
        verified-by: verified-by,
        total-credits: total-credits,
        available-credits: total-credits,
        price-per-credit: price-per-credit,
        created-at: block-height,
        is-active: true
      })
      
      ;; Mint tokens representing the carbon credits
      (try! (ft-mint? carbon-offset-token total-credits (as-contract tx-sender)))
      (var-set total-supply (+ (var-get total-supply) total-credits))
      
      ;; Update counters
      (var-set next-project-id (+ project-id u1))
      (var-set total-projects (+ (var-get total-projects) u1))
      
      (ok project-id))))

;; Function 2: Purchase Carbon Credits
;; Allows users to purchase and retire carbon offset credits
(define-public (purchase-carbon-credits (project-id uint) (credit-amount uint))
  (let ((project (unwrap! (map-get? carbon-projects project-id) err-project-not-found))
        (total-cost (* credit-amount (get price-per-credit project))))
    (begin
      ;; Validate purchase request
      (asserts! (> credit-amount u0) err-invalid-amount)
      (asserts! (get is-active project) err-project-not-found)
      (asserts! (>= (get available-credits project) credit-amount) err-insufficient-credits)
      
      ;; Transfer payment to contract
      (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
      
      ;; Transfer carbon credit tokens to purchaser
      (try! (as-contract (ft-transfer? carbon-offset-token credit-amount tx-sender tx-sender)))
      
      ;; Immediately retire/burn the credits (offset achieved)
      (try! (ft-burn? carbon-offset-token credit-amount tx-sender))
      
      ;; Update project availability
      (map-set carbon-projects project-id (merge project {
        available-credits: (- (get available-credits project) credit-amount)
      }))
      
      ;; Track user's total retired credits
      (map-set user-credits tx-sender
        (+ (default-to u0 (map-get? user-credits tx-sender)) credit-amount))
      
      ;; Track purchase history
      (map-set project-purchases {project-id: project-id, purchaser: tx-sender}
        (+ (default-to u0 (map-get? project-purchases {project-id: project-id, purchaser: tx-sender})) credit-amount))
      
      ;; Update global retirement counter
      (var-set total-credits-retired (+ (var-get total-credits-retired) credit-amount))
      (var-set total-supply (- (var-get total-supply) credit-amount))
      
      (ok credit-amount))))

;; Get project details
(define-read-only (get-project-details (project-id uint))
  (ok (map-get? carbon-projects project-id)))

;; Get user's total retired credits
(define-read-only (get-user-retired-credits (user principal))
  (ok (default-to u0 (map-get? user-credits user))))

;; Get user's purchases from specific project
(define-read-only (get-user-project-purchases (project-id uint) (user principal))
  (ok (default-to u0 (map-get? project-purchases {project-id: project-id, purchaser: user}))))

;; Get platform statistics
(define-read-only (get-platform-stats)
  (ok {
    total-projects: (var-get total-projects),
    total-supply: (var-get total-supply),
    total-credits-retired: (var-get total-credits-retired),
    next-project-id: (var-get next-project-id)
  }))

;; Get token information
(define-read-only (get-token-info)
  (ok {
    name: (var-get token-name),
    symbol: (var-get token-symbol),
    decimals: (var-get token-decimals),
    total-supply: (var-get total-supply)
  }))

;; Check project availability
(define-read-only (is-project-active (project-id uint))
  (match (map-get? carbon-projects project-id)
    project (ok (and (get is-active project) (> (get available-credits project) u0)))
    (err err-project-not-found)))