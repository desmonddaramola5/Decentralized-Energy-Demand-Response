;; utility-verification.clar
;; Contract to validate energy providers

(define-data-var admin principal tx-sender)

;; Map to store verified utilities
(define-map verified-utilities principal
  {
    name: (string-utf8 100),
    region: (string-utf8 100),
    verified: bool,
    verification-date: uint
  }
)

;; Register a new utility
(define-public (register-utility (name (string-utf8 100)) (region (string-utf8 100)))
  (let ((utility-data {
          name: name,
          region: region,
          verified: false,
          verification-date: u0
        }))
    (if (is-eq tx-sender (var-get admin))
      (ok (map-set verified-utilities tx-sender utility-data))
      (err u403))))

;; Verify a utility
(define-public (verify-utility (utility-address principal))
  (let ((current-time (unwrap-panic (get-block-info? time u0))))
    (if (is-eq tx-sender (var-get admin))
      (match (map-get? verified-utilities utility-address)
        utility-data (ok (map-set verified-utilities
                          utility-address
                          (merge utility-data {
                            verified: true,
                            verification-date: current-time
                          })))
        (err u404))
      (err u403))))

;; Check if a utility is verified
(define-read-only (is-verified (utility-address principal))
  (match (map-get? verified-utilities utility-address)
    utility-data (get verified utility-data)
    false))

;; Get utility information
(define-read-only (get-utility-info (utility-address principal))
  (map-get? verified-utilities utility-address))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (ok (var-set admin new-admin))
    (err u403)))
