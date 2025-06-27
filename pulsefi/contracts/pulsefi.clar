;; Fitness Challenge Smart Contract

;; Define trait for reward token
(define-trait token-interface
    ((transfer (uint principal (optional (buff 34))) (response bool uint)))
)

;; Define data structures
(define-data-var total-competitions uint u0)
(define-data-var incentive-token principal tx-sender) ;; Reward token contract address
(define-data-var incentive-quantity uint u100) ;; Reward amount in tokens

;; Constants for validation
(define-constant MIN_TARGET u1)
(define-constant MAX_TARGET u1000000) ;; 1 million steps/calories/etc
(define-constant MIN_TIMESPAN u1440) ;; Minimum 1 day (in blocks)
(define-constant MAX_TIMESPAN u525600) ;; Maximum 1 year (in blocks)
(define-constant MAX_ADVANCEMENT u1000000) ;; Maximum progress value

(define-map competitions
  { competition-id: uint }
  {
    organizer: principal,
    target: uint,
    launch-time: uint,
    finish-time: uint,
    members: (list 50 principal),
    finishers: (list 50 principal)
  }
)

(define-map participant-advancement
  { participant: principal, competition-id: uint }
  uint ;; Progress value (e.g., steps, calories burned)
)

;; Error codes
(define-constant ERR_NOT_LAUNCHED (err u1))
(define-constant ERR_FINISHED (err u2))
(define-constant ERR_ALREADY_MEMBER (err u3))
(define-constant ERR_NOT_MEMBER (err u4))
(define-constant ERR_TARGET_NOT_REACHED (err u5))
(define-constant ERR_TRANSFER_UNSUCCESSFUL (err u6))
(define-constant ERR_INVALID_TARGET (err u7))
(define-constant ERR_INVALID_TIMESPAN (err u8))
(define-constant ERR_INVALID_ADVANCEMENT (err u9))
(define-constant ERR_INVALID_COMPETITION (err u10))
(define-constant ERR_INVALID_TOKEN_CONTRACT (err u11))

;; Create a new fitness challenge
(define-public (create-competition (target uint) (launch-time uint) (finish-time uint))
  (let 
    (
      (competition-id (+ (var-get total-competitions) u1))
      (timespan (- finish-time launch-time))
    )
    ;; Validate inputs
    (asserts! (and (>= target MIN_TARGET) (<= target MAX_TARGET)) ERR_INVALID_TARGET)
    (asserts! (>= launch-time block-height) ERR_NOT_LAUNCHED)
    (asserts! (and (>= timespan MIN_TIMESPAN) (<= timespan MAX_TIMESPAN)) ERR_INVALID_TIMESPAN)
    
    (map-set competitions
      { competition-id: competition-id }
      {
        organizer: tx-sender,
        target: target,
        launch-time: launch-time,
        finish-time: finish-time,
        members: (list tx-sender),
        finishers: (list)
      }
    )
    (var-set total-competitions competition-id)
    (ok competition-id)
  )
)

;; Join an existing fitness challenge
(define-public (join-competition (competition-id uint))
  (let 
    (
      (current-total (var-get total-competitions))
    )
    ;; Validate challenge-id
    (asserts! (<= competition-id current-total) ERR_INVALID_COMPETITION)
    (let ((competition (unwrap! (map-get? competitions { competition-id: competition-id }) ERR_INVALID_COMPETITION)))
      (asserts! (>= block-height (get launch-time competition)) ERR_NOT_LAUNCHED)
      (asserts! (< block-height (get finish-time competition)) ERR_FINISHED)
      (asserts! (not (contains? (get members competition) tx-sender)) ERR_ALREADY_MEMBER)
      (map-set competitions
        { competition-id: competition-id }
        (merge competition
          { members: (unwrap-panic (as-max-len? (append (get members competition) tx-sender) u50)) }
        )
      )
      (ok true)
    )
  )
)

;; Submit progress for a challenge
(define-public (submit-advancement (competition-id uint) (advancement uint))
  (let 
    (
      (current-total (var-get total-competitions))
    )
    ;; Validate inputs
    (asserts! (<= competition-id current-total) ERR_INVALID_COMPETITION)
    (asserts! (<= advancement MAX_ADVANCEMENT) ERR_INVALID_ADVANCEMENT)
    
    (let ((competition (unwrap! (map-get? competitions { competition-id: competition-id }) ERR_INVALID_COMPETITION)))
      (asserts! (>= block-height (get launch-time competition)) ERR_NOT_LAUNCHED)
      (asserts! (< block-height (get finish-time competition)) ERR_FINISHED)
      (asserts! (contains? (get members competition) tx-sender) ERR_NOT_MEMBER)
      (map-set participant-advancement { participant: tx-sender, competition-id: competition-id } advancement)
      (ok true)
    )
  )
)

;; Validate reward token contract
(define-private (validate-incentive-token (incentive-token-contract <token-interface>))
  (is-eq (contract-of incentive-token-contract) (var-get incentive-token))
)

;; Claim reward for completing a challenge
(define-public (claim-incentive (competition-id uint) (incentive-token-contract <token-interface>))
  (let 
    (
      (current-total (var-get total-competitions))
    )
    ;; Validate challenge-id and reward token
    (asserts! (<= competition-id current-total) ERR_INVALID_COMPETITION)
    (asserts! (validate-incentive-token incentive-token-contract) ERR_INVALID_TOKEN_CONTRACT)
    
    (let ((competition (unwrap! (map-get? competitions { competition-id: competition-id }) ERR_INVALID_COMPETITION)))
      (asserts! (>= block-height (get finish-time competition)) ERR_FINISHED)
      (asserts! (contains? (get members competition) tx-sender) ERR_NOT_MEMBER)
      (let ((advancement (unwrap! (map-get? participant-advancement { participant: tx-sender, competition-id: competition-id }) ERR_TARGET_NOT_REACHED)))
        (asserts! (>= advancement (get target competition)) ERR_TARGET_NOT_REACHED)
        (map-set competitions
          { competition-id: competition-id }
          (merge competition
            { finishers: (unwrap-panic (as-max-len? (append (get finishers competition) tx-sender) u50)) }
          )
        )
        (match (contract-call? incentive-token-contract transfer (var-get incentive-quantity) tx-sender none)
          success (ok true)
          error ERR_TRANSFER_UNSUCCESSFUL)
      )
    )
  )
)

;; Helper function to check if a principal is in a list
(define-private (contains? (collection (list 50 principal)) (participant principal))
  (is-some (index-of collection participant))
)

;; Read-only function to get challenge details
(define-read-only (get-competition-details (competition-id uint))
  (let 
    (
      (current-total (var-get total-competitions))
    )
    (if (<= competition-id current-total)
      (map-get? competitions { competition-id: competition-id })
      none
    )
  )
)

;; Read-only function to get user progress
(define-read-only (get-participant-advancement (participant principal) (competition-id uint))
  (let 
    (
      (current-total (var-get total-competitions))
    )
    (if (<= competition-id current-total)
      (map-get? participant-advancement { participant: participant, competition-id: competition-id })
      none
    )
  )
)