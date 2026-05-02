---
name: loop-detector
description: 디버깅 / dev-experiment 흐름에서 oscillation 감지. 직전·N-2 시도의 diff hash 를 비교해 같은 변경이 반복되면 Contrarian 등 페르소나를 추천. 3-failure rule 트리거 전 조기 개입.
user-invocable: false
---

# Loop Detector

**같은 가설로 반복 시도하는 oscillation 을 자율적으로 감지** 하는 skill. 본 skill 은 `rules/01-principles.md` 의 \"단일 가설 직렬 추격 금지\" 원칙의 자율 적용 메커니즘이다.

## When to Invoke

| 트리거 | 호출 |
|---|---|
| 디버깅 중 같은 함수·같은 파일에 2회 이상 수정 시도 | **자동** (각 수정 직후) |
| dev-experiment 흐름에서 Hypothesis 변경 없이 Implement 재시도 | 자동 |
| 3-failure rule 발동 직전 (2회 실패 후) | 자동 |
| 사용자가 \"같은 거 반복하는 것 같은데\" 명시 | 즉시 호출 |

## 감지 알고리즘

### Step 1 — 시도 기록

각 수정 시도마다 다음 4-tuple 을 session-log.md 또는 메모리에 기록:

```yaml
attempt:
  id: 3                              # 시도 번호 (1-based)
  hypothesis: "Redis 타임아웃이 1초로 짧음"
  files_changed: ["src/cache.py"]    # 수정 파일 목록
  diff_hash: "a1b2c3d4"              # 수정 내용의 짧은 hash (line-level diff)
  result: "fail"                     # pass | fail | partial
```

`diff_hash` 는 변경된 라인의 sorted set 을 SHA-1 8자로 자른 형태. 정확한 산출은 본 skill 호출 시 본인이 grep/diff 로 산출 (1단계는 hash 비교 근거만 절차로 제공, 자동화는 SU3 info-gain skill 에서).

### Step 2 — 비교 규칙

| 비교 대상 | 일치 신호 |
|---|---|
| **직전 시도 (N-1)** | hypothesis 동일 + diff_hash 동일 → **stuck**: 같은 코드에 같은 의도, 결과만 기대 |
| **N-2 시도** | hypothesis 동일 + diff_hash 동일 → **oscillation**: 한 번 다른 시도 후 원복 |
| 3+ 시도, 모두 다른 hash | **spinning** (방향 못 잡음) |
| 3+ 시도, 하나는 통과 했지만 다른 변경으로 다시 깸 | **regression loop** |

각 신호별 다른 페르소나로 라우팅 (oracle-consultation/SKILL.md Routing 표 참조):

| 신호 | 1순위 페르소나 |
|---|---|
| stuck | **Contrarian** (가설 반증) |
| oscillation | **Contrarian** (대안 가설 3개) |
| spinning | **Hacker** (제약 위반 / 새 경로) |
| regression loop | **Architect** (책임 경계 재검토) |

### Step 3 — 추천 출력

감지 즉시 다음 형태로 출력:

```markdown
## Loop Detector

- **신호**: oscillation 감지
- **근거**: 시도 #3 의 diff_hash 가 시도 #1 과 일치 (a1b2c3d4)
- **반복된 가설**: \"Redis 타임아웃이 1초로 짧음\" (시도 #1, #3)
- **권장 페르소나**: Contrarian
- **권장 행동**: oracle-consultation 의 Contrarian 페르소나로 위임 (`personas/contrarian.md`)
- **3-failure rule 까지 잔여**: 1회 (다음 실패 시 자동 발동)
```

## 우회 / 예외

- 사용자가 \"loop-detector skip\" 명시 → 본 skill 호출 자체 건너뜀
- diff_hash 가 다르지만 의도가 같은 \"의미적 oscillation\" 은 본 1단계에서 미감지 (SU3 info-gain 의 trajectory metric 으로 보강 예정)
- 의도된 retry (예: flaky 테스트 재실행) 는 사용자가 hypothesis 에 \"flaky retry\" 명시하면 oscillation 신호에서 제외

## 통합

- **3-failure rule** (`rules/01-principles.md` Debugging) 의 조기 보강. 3회 실패 트리거 *전에* 2회 시점에서 oscillation 감지 시 페르소나 호출 권장
- **oracle-consultation/SKILL.md** Routing 표와 1:1 매핑
- **dev-experiment skill** 의 30분 time-box 안에서 호출 가능 — oscillation 감지 시 30분 소진 전 즉시 중단 신호
- **session-log.md** 의 \"발견사항\" 섹션에 신호 기록 권장 (SU3 에서 정형 4-field 강제 예정)

## 안티패턴

- \"감지했지만 그냥 한 번 더\" → 신호 무시 = self-bootstrap 검증 실패. 페르소나로 즉시 위임
- \"diff_hash 산출이 귀찮으니 hypothesis 만 비교\" → diff_hash 일치가 oscillation 의 강한 증거. hypothesis 만 보면 false negative
- \"자동 라우팅이 없으니 추천도 무의미\" → 1단계 의도. 본 skill 의 추천을 본인이 명시 채택해 페르소나로 위임 = self-bootstrap. 자동 라우팅은 SU2
