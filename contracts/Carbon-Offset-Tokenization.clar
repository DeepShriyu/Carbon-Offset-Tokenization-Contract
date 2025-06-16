carbon-offset-tokenization.clar
;; Carbon Offset Tokenization Contract
;; Users can register carbon credits and retire them to offset emissions

(define-map credits
  uint
  { issuer: principal, amount: uint, retired: bool })

(define-data-var credit-count uint u0)

(define-constant err-already-retired (err u100))
(define-constant err-not-found (err u101))

;; Register new carbon credits
(define-public (register-credit (amount uint))
  (let ((id (var-get credit-count)))
    (begin
      (map-set credits id { issuer: tx-sender, amount: amount, retired: false })
      (var-set credit-count (+ id u1))
      (ok id))))

;; Retire carbon credits by ID
(define-public (retire-credit (credit-id uint))
  (match (map-get? credits credit-id)
    credit
    (begin
      (asserts! (not (get retired credit)) err-already-retired)
      (map-set credits credit-id
               { issuer: (get issuer credit),
                 amount: (get amount credit),
                 retired: true })
      (ok true))
    err-not-found))
