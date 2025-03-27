;; maintenance-protocol.clar
;; Documents habitat management practices

(define-data-var next-protocol-id uint u0)
(define-data-var next-activity-id uint u0)

;; Maintenance protocols
(define-map maintenance-protocols
  { protocol-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    habitat-type: (string-utf8 50),
    frequency: (string-utf8 50), ;; daily, weekly, monthly, quarterly, annually
    season: (string-utf8 50), ;; spring, summer, fall, winter, year-round
    created-by: principal,
    creation-date: uint,
    last-updated: uint,
    active: bool
  }
)

;; Maintenance activities performed at sites
(define-map maintenance-activities
  { activity-id: uint }
  {
    site-id: uint,
    protocol-id: uint,
    performed-by: principal,
    date-performed: uint,
    notes: (string-utf8 500),
    weather-conditions: (string-utf8 100),
    effectiveness-rating: uint, ;; 1-10 scale
    images-hash: (optional (string-utf8 64)) ;; IPFS hash or similar for images
  }
)

;; Create a new maintenance protocol
(define-public (create-protocol
    (name (string-utf8 100))
    (description (string-utf8 500))
    (habitat-type (string-utf8 50))
    (frequency (string-utf8 50))
    (season (string-utf8 50)))
  (let
    ((new-id (var-get next-protocol-id))
     (current-block block-height))
    (begin
      (var-set next-protocol-id (+ new-id u1))
      (map-set maintenance-protocols
        { protocol-id: new-id }
        {
          name: name,
          description: description,
          habitat-type: habitat-type,
          frequency: frequency,
          season: season,
          created-by: tx-sender,
          creation-date: current-block,
          last-updated: current-block,
          active: true
        }
      )
      (ok new-id)
    )
  )
)

;; Update an existing protocol
(define-public (update-protocol
    (protocol-id uint)
    (name (string-utf8 100))
    (description (string-utf8 500))
    (habitat-type (string-utf8 50))
    (frequency (string-utf8 50))
    (season (string-utf8 50)))
  (let
    ((protocol (map-get? maintenance-protocols { protocol-id: protocol-id })))
    (if (is-some protocol)
      (let
        ((unwrapped-protocol (unwrap-panic protocol)))
        (if (is-eq tx-sender (get created-by unwrapped-protocol))
          (begin
            (map-set maintenance-protocols
              { protocol-id: protocol-id }
              {
                name: name,
                description: description,
                habitat-type: habitat-type,
                frequency: frequency,
                season: season,
                created-by: (get created-by unwrapped-protocol),
                creation-date: (get creation-date unwrapped-protocol),
                last-updated: block-height,
                active: (get active unwrapped-protocol)
              }
            )
            (ok true)
          )
          (err u403) ;; Unauthorized - not the creator
        )
      )
      (err u404) ;; Protocol not found
    )
  )
)

;; Set protocol active status
(define-public (set-protocol-status (protocol-id uint) (active bool))
  (let
    ((protocol (map-get? maintenance-protocols { protocol-id: protocol-id })))
    (if (is-some protocol)
      (let
        ((unwrapped-protocol (unwrap-panic protocol)))
        (if (is-eq tx-sender (get created-by unwrapped-protocol))
          (begin
            (map-set maintenance-protocols
              { protocol-id: protocol-id }
              (merge unwrapped-protocol { active: active, last-updated: block-height })
            )
            (ok true)
          )
          (err u403) ;; Unauthorized - not the creator
        )
      )
      (err u404) ;; Protocol not found
    )
  )
)

;; Record a maintenance activity
(define-public (record-maintenance-activity
    (site-id uint)
    (protocol-id uint)
    (date-performed uint)
    (notes (string-utf8 500))
    (weather-conditions (string-utf8 100))
    (effectiveness-rating uint)
    (images-hash (optional (string-utf8 64))))
  (let
    ((new-id (var-get next-activity-id))
     (protocol (map-get? maintenance-protocols { protocol-id: protocol-id })))
    (if (is-some protocol)
      (begin
        (asserts! (<= effectiveness-rating u10) (err u400)) ;; Rating must be 1-10
        (var-set next-activity-id (+ new-id u1))
        (map-set maintenance-activities
          { activity-id: new-id }
          {
            site-id: site-id,
            protocol-id: protocol-id,
            performed-by: tx-sender,
            date-performed: date-performed,
            notes: notes,
            weather-conditions: weather-conditions,
            effectiveness-rating: effectiveness-rating,
            images-hash: images-hash
          }
        )
        (ok new-id)
      )
      (err u404) ;; Protocol not found
    )
  )
)

;; Get protocol information
(define-read-only (get-protocol (protocol-id uint))
  (map-get? maintenance-protocols { protocol-id: protocol-id })
)

;; Get maintenance activity information
(define-read-only (get-maintenance-activity (activity-id uint))
  (map-get? maintenance-activities { activity-id: activity-id })
)

;; Get protocols by habitat type
(define-read-only (get-protocols-for-habitat (habitat-type (string-utf8 50)))
  ;; In a real implementation, this would need a different data structure
  ;; to efficiently query protocols by habitat type
  ;; This is a placeholder for the concept
  (ok true)
)
