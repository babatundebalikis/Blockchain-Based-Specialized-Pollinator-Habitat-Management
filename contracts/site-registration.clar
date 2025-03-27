;; site-registration.clar
;; Records details of pollinator-friendly areas

(define-data-var next-site-id uint u0)

(define-map sites
  { site-id: uint }
  {
    name: (string-utf8 100),
    location: (string-utf8 100),
    coordinates: (string-utf8 50),
    area-size: uint,  ;; in square meters
    habitat-type: (string-utf8 50),
    owner: principal,
    registration-date: uint,
    active: bool
  }
)

;; Register a new pollinator habitat site
(define-public (register-site
    (name (string-utf8 100))
    (location (string-utf8 100))
    (coordinates (string-utf8 50))
    (area-size uint)
    (habitat-type (string-utf8 50)))
  (let
    ((new-id (var-get next-site-id)))
    (begin
      (var-set next-site-id (+ new-id u1))
      (map-set sites
        { site-id: new-id }
        {
          name: name,
          location: location,
          coordinates: coordinates,
          area-size: area-size,
          habitat-type: habitat-type,
          owner: tx-sender,
          registration-date: block-height,
          active: true
        }
      )
      (ok new-id)
    )
  )
)

;; Update site information
(define-public (update-site-info
    (site-id uint)
    (name (string-utf8 100))
    (location (string-utf8 100))
    (coordinates (string-utf8 50))
    (area-size uint)
    (habitat-type (string-utf8 50)))
  (let
    ((site (map-get? sites { site-id: site-id })))
    (if (is-some site)
      (let
        ((unwrapped-site (unwrap-panic site)))
        (if (is-eq tx-sender (get owner unwrapped-site))
          (begin
            (map-set sites
              { site-id: site-id }
              {
                name: name,
                location: location,
                coordinates: coordinates,
                area-size: area-size,
                habitat-type: habitat-type,
                owner: (get owner unwrapped-site),
                registration-date: (get registration-date unwrapped-site),
                active: (get active unwrapped-site)
              }
            )
            (ok true)
          )
          (err u403) ;; Unauthorized - not the owner
        )
      )
      (err u404) ;; Site not found
    )
  )
)

;; Set site active status
(define-public (set-site-status (site-id uint) (active bool))
  (let
    ((site (map-get? sites { site-id: site-id })))
    (if (is-some site)
      (let
        ((unwrapped-site (unwrap-panic site)))
        (if (is-eq tx-sender (get owner unwrapped-site))
          (begin
            (map-set sites
              { site-id: site-id }
              (merge unwrapped-site { active: active })
            )
            (ok true)
          )
          (err u403) ;; Unauthorized - not the owner
        )
      )
      (err u404) ;; Site not found
    )
  )
)

;; Transfer site ownership
(define-public (transfer-site-ownership (site-id uint) (new-owner principal))
  (let
    ((site (map-get? sites { site-id: site-id })))
    (if (is-some site)
      (let
        ((unwrapped-site (unwrap-panic site)))
        (if (is-eq tx-sender (get owner unwrapped-site))
          (begin
            (map-set sites
              { site-id: site-id }
              (merge unwrapped-site { owner: new-owner })
            )
            (ok true)
          )
          (err u403) ;; Unauthorized - not the owner
        )
      )
      (err u404) ;; Site not found
    )
  )
)

;; Get site information
(define-read-only (get-site (site-id uint))
  (map-get? sites { site-id: site-id })
)

;; Check if a site is active
(define-read-only (is-site-active (site-id uint))
  (let
    ((site (map-get? sites { site-id: site-id })))
    (if (is-some site)
      (get active (unwrap-panic site))
      false
    )
  )
)

;; Get site owner
(define-read-only (get-site-owner (site-id uint))
  (let
    ((site (map-get? sites { site-id: site-id })))
    (if (is-some site)
      (ok (get owner (unwrap-panic site)))
      (err u404) ;; Site not found
    )
  )
)
