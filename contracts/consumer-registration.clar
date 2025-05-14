;; consumer-registration.clar
;; Contract to register energy consumers

(define-data-var admin principal tx-sender)

;; Map to store registered consumers
(define-map consumers principal
  {
    name: (string-utf8 100),
    location: (string-utf8 100),
    max-capacity: uint,
    registration-date: uint
  }
)

;; Register a new consumer
(define-public (register-consumer
                (name (string-utf8 100))
                (location (string-utf8 100))
                (max-capacity uint))
  (let ((current-time (unwrap-panic (get-block-info? time u0)))
        (consumer-data {
          name: name,
          location: location,
          max-capacity: max-capacity,
          registration-date: current-time
        }))
    (ok (map-set consumers tx-sender consumer-data))))

;; Update consumer information
(define-public (update-consumer-info
                (name (string-utf8 100))
                (location (string-utf8 100))
                (max-capacity uint))
  (match (map-get? consumers tx-sender)
    consumer-data (ok (map-set consumers
                        tx-sender
                        (merge consumer-data {
                          name: name,
                          location: location,
                          max-capacity: max-capacity
                        })))
    (err u404)))

;; Check if a consumer is registered
(define-read-only (is-registered (consumer-address principal))
  (is-some (map-get? consumers consumer-address)))

;; Get consumer information
(define-read-only (get-consumer-info (consumer-address principal))
  (map-get? consumers consumer-address))

;; Remove a consumer (admin only)
(define-public (remove-consumer (consumer-address principal))
  (if (is-eq tx-sender (var-get admin))
    (ok (map-delete consumers consumer-address))
    (err u403)))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (ok (var-set admin new-admin))
    (err u403)))
