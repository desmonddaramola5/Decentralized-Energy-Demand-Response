;; load-forecasting.clar
;; Contract to predict peak demand periods

(define-data-var admin principal tx-sender)

;; Map to store utility contract principals that can submit forecasts
(define-map authorized-utilities principal bool)

;; Map to store forecasts by date and hour
(define-map forecasts {date: uint, hour: uint}
  {
    predicted-load: uint,
    is-peak: bool,
    submitted-by: principal,
    submission-time: uint
  }
)

;; Authorize a utility to submit forecasts
(define-public (authorize-utility (utility-address principal))
  (if (is-eq tx-sender (var-get admin))
    (ok (map-set authorized-utilities utility-address true))
    (err u403)))

;; Submit a load forecast
(define-public (submit-forecast (date uint) (hour uint) (predicted-load uint) (is-peak bool))
  (let ((current-time (unwrap-panic (get-block-info? time u0))))
    (if (default-to false (map-get? authorized-utilities tx-sender))
      (ok (map-set forecasts
            {date: date, hour: hour}
            {
              predicted-load: predicted-load,
              is-peak: is-peak,
              submitted-by: tx-sender,
              submission-time: current-time
            }))
      (err u403))))

;; Get forecast for a specific date and hour
(define-read-only (get-forecast (date uint) (hour uint))
  (map-get? forecasts {date: date, hour: hour}))

;; Check if a specific date and hour is predicted to be a peak period
(define-read-only (is-peak-period (date uint) (hour uint))
  (match (map-get? forecasts {date: date, hour: hour})
    forecast-data (get is-peak forecast-data)
    false))

;; Revoke utility authorization
(define-public (revoke-utility (utility-address principal))
  (if (is-eq tx-sender (var-get admin))
    (ok (map-delete authorized-utilities utility-address))
    (err u403)))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (ok (var-set admin new-admin))
    (err u403)))
