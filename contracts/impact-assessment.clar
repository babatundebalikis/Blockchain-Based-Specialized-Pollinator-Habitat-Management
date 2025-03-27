;; impact-assessment.clar
;; Monitors pollinator population responses

(define-data-var next-survey-id uint u0)
(define-data-var next-species-id uint u0)

;; Pollinator species database
(define-map pollinator-species
  { species-id: uint }
  {
    scientific-name: (string-utf8 100),
    common-name: (string-utf8 100),
    species-type: (string-utf8 50), ;; bee, butterfly, moth, bird, etc.
    description: (string-utf8 200),
    conservation-status: (string-utf8 50), ;; common, threatened, endangered, etc.
    added-by: principal,
    verified: bool
  }
)

;; Pollinator surveys conducted at sites
(define-map pollinator-surveys
  { survey-id: uint }
  {
    site-id: uint,
    survey-date: uint,
    weather-conditions: (string-utf8 100),
    temperature: int, ;; in Celsius
    wind-speed: uint, ;; in km/h
    conducted-by: principal,
    survey-method: (string-utf8 100),
    duration-minutes: uint,
    notes: (string-utf8 500)
  }
)

;; Observations of pollinators during surveys
(define-map pollinator-observations
  { survey-id: uint, species-id: uint }
  {
    count: uint,
    behavior: (string-utf8 100), ;; foraging, nesting, resting, etc.
    plant-interaction: (optional uint), ;; plant-id if interacting with a specific plant
    notes: (string-utf8 200)
  }
)

;; Add a new pollinator species
(define-public (add-pollinator-species
    (scientific-name (string-utf8 100))
    (common-name (string-utf8 100))
    (species-type (string-utf8 50))
    (description (string-utf8 200))
    (conservation-status (string-utf8 50)))
  (let
    ((new-id (var-get next-species-id)))
    (begin
      (var-set next-species-id (+ new-id u1))
      (map-set pollinator-species
        { species-id: new-id }
        {
          scientific-name: scientific-name,
          common-name: common-name,
          species-type: species-type,
          description: description,
          conservation-status: conservation-status,
          added-by: tx-sender,
          verified: false
        }
      )
      (ok new-id)
    )
  )
)

;; Verify a pollinator species (by authorized verifiers)
(define-public (verify-pollinator-species (species-id uint) (verified bool))
  (let
    ((species (map-get? pollinator-species { species-id: species-id })))
    (if (is-some species)
      (begin
        ;; In a real implementation, check if tx-sender is an authorized verifier
        (map-set pollinator-species
          { species-id: species-id }
          (merge (unwrap-panic species) { verified: verified })
        )
        (ok true)
      )
      (err u404) ;; Species not found
    )
  )
)

;; Record a pollinator survey
(define-public (record-survey
    (site-id uint)
    (survey-date uint)
    (weather-conditions (string-utf8 100))
    (temperature int)
    (wind-speed uint)
    (survey-method (string-utf8 100))
    (duration-minutes uint)
    (notes (string-utf8 500)))
  (let
    ((new-id (var-get next-survey-id)))
    (begin
      (var-set next-survey-id (+ new-id u1))
      (map-set pollinator-surveys
        { survey-id: new-id }
        {
          site-id: site-id,
          survey-date: survey-date,
          weather-conditions: weather-conditions,
          temperature: temperature,
          wind-speed: wind-speed,
          conducted-by: tx-sender,
          survey-method: survey-method,
          duration-minutes: duration-minutes,
          notes: notes
        }
      )
      (ok new-id)
    )
  )
)

;; Record a pollinator observation during a survey
(define-public (record-observation
    (survey-id uint)
    (species-id uint)
    (count uint)
    (behavior (string-utf8 100))
    (plant-interaction (optional uint))
    (notes (string-utf8 200)))
  (let
    ((survey (map-get? pollinator-surveys { survey-id: survey-id }))
     (species (map-get? pollinator-species { species-id: species-id })))
    (if (and (is-some survey) (is-some species))
      (begin
        (map-set pollinator-observations
          { survey-id: survey-id, species-id: species-id }
          {
            count: count,
            behavior: behavior,
            plant-interaction: plant-interaction,
            notes: notes
          }
        )
        (ok true)
      )
      (err u404) ;; Survey or species not found
    )
  )
)

;; Calculate total pollinator count for a survey
(define-read-only (get-survey-pollinator-count (survey-id uint))
  ;; In a real implementation, this would need a different data structure
  ;; to efficiently calculate the sum of all observations for a survey
  ;; This is a placeholder for the concept
  (ok u0)
)

;; Get pollinator species information
(define-read-only (get-pollinator-species (species-id uint))
  (map-get? pollinator-species { species-id: species-id })
)

;; Get survey information
(define-read-only (get-survey (survey-id uint))
  (map-get? pollinator-surveys { survey-id: survey-id })
)

;; Get observation information
(define-read-only (get-observation (survey-id uint) (species-id uint))
  (map-get? pollinator-observations { survey-id: survey-id, species-id: species-id })
)

;; Get site biodiversity score
(define-read-only (get-site-biodiversity-score (site-id uint))
  ;; In a real implementation, this would calculate a biodiversity score
  ;; based on the number of different species observed at the site
  ;; This is a placeholder for the concept
  (ok u0)
)

;; Get site pollinator trend
(define-read-only (get-site-pollinator-trend (site-id uint) (species-id uint) (start-date uint) (end-date uint))
  ;; In a real implementation, this would analyze the trend of a specific pollinator
  ;; at a site over time, comparing counts between the start and end dates
  ;; This is a placeholder for the concept
  (ok { increasing: true, percent-change: u0 })
)
