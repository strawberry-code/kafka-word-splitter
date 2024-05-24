# Docker to Podman Migration - Technical Notes

**Migration Date:** 2025-11-02
**Wave:** 1 of 3 (DevOps Infrastructure)
**Status:** Complete
**DevOps Engineer:** Infrastructure Team

---

## Executive Summary

This document outlines the technical changes made during the migration from Docker to Podman for the Kafka Word Splitter project. The migration maintains 100% backward compatibility while enabling Podman as the primary container runtime.

## Changes Made

### 1. Compose File Migration

**File:** `docker-compose.yml` → `compose.yml`

**Key Changes:**
- **Version Update:** `version: '2'` → `version: '3.8'`
  - Reason: Better Podman compatibility and modern Docker Compose features

- **Docker Socket Mount Removed:** Eliminated `/var/run/docker.sock:/var/run/docker.sock`
  - Reason: Not needed for Kafka services, causes Podman compatibility issues
  - Security: Reduces attack surface by not exposing container runtime socket

- **Explicit Container Names:** Added `container_name` directives
  - `kafka-word-splitter-zookeeper` (Zookeeper)
  - `kafka-word-splitter-kafka` (Kafka broker)
  - Reason: Consistent naming across Docker and Podman, easier troubleshooting

- **Network Configuration:** Added explicit bridge network
  - Network name: `kafka-network`
  - Driver: bridge
  - Reason: Ensures consistent networking behavior across runtimes

- **Startup Order:** Added `depends_on` directive
  - Kafka depends on Zookeeper
  - Reason: Ensures proper initialization sequence

**Backward Compatibility:**
- Scripts fall back to `docker-compose.yml` if `compose.yml` not found
- All original functionality preserved

### 2. Script Enhancements

#### start-kafka.sh (Enhanced)

**Original:** Single line Docker Compose command

**New Features:**
- **Runtime Auto-Detection:** Detects and uses available runtime
  - Priority: Podman → Docker
  - Supports: `podman compose`, `podman-compose`, `docker compose`, `docker-compose`

- **Error Handling:** Comprehensive validation and helpful error messages

- **Service Validation:** Confirms containers started successfully

- **User Feedback:** Color-coded output with status indicators

- **Connection Info:** Displays broker and Zookeeper endpoints

- **Next Steps:** Guides users on what to do next

#### scripts/stop-kafka.sh (New)

**Purpose:** Gracefully stop Kafka infrastructure

**Features:**
- Runtime auto-detection
- Clean shutdown using compose down
- Verification of service stoppage
- Clear status reporting

#### scripts/kafka-status.sh (New)

**Purpose:** Real-time infrastructure status monitoring

**Features:**
- Container runtime detection and display
- Container status checking (running/stopped)
- Port connectivity testing (2181, 9092)
- Kafka topic listing
- Overall system health summary
- Color-coded status indicators

#### scripts/create-topics.sh (New)

**Purpose:** Automated Kafka topic creation

**Features:**
- Creates topics 3-10 (required by application)
- Runtime auto-detection
- Validates Kafka is running before proceeding
- Checks for existing topics (idempotent)
- Lists all topics after creation
- Clear success/failure indicators

#### scripts/validate-podman.sh (New)

**Purpose:** Comprehensive migration validation

**Validation Checks:**
1. Podman installation verification
2. Compose tool availability
3. compose.yml syntax validation
4. Docker socket mount absence verification
5. Container naming validation
6. Network configuration verification
7. Script existence and executability
8. Runtime detection in scripts
9. Service startup testing
10. Connectivity testing (ports 2181, 9092)
11. Topic creation capability
12. Documentation completeness

**Output:** Detailed pass/fail report with counts

### 3. Documentation

#### MIGRATION-NOTES.md (This Document)

Technical reference for engineering team

#### .podman-migration-checklist.md

Step-by-step validation checklist for manual review

---

## Podman-Specific Configurations

### Differences from Docker

1. **No Docker Daemon:** Podman is daemonless
   - Benefit: Better security model, no single point of failure
   - Impact: Different process model, rootless by default

2. **Rootless by Default:** Podman can run without root
   - Benefit: Enhanced security
   - Impact: Different user permissions, port mappings

3. **Docker Socket:** Not applicable to Podman
   - Impact: All references removed from configuration

4. **Compose Compatibility:** Two variants supported
   - `podman compose` (built-in, recommended)
   - `podman-compose` (separate tool, fallback)

### Platform-Specific Notes

#### macOS

**Podman Machine Required:**
```bash
podman machine init
podman machine start
```

**Port Forwarding:**
- Ports 2181 and 9092 are automatically forwarded
- No additional configuration needed

**Storage:**
- Uses virtual machine storage
- Default: `~/.local/share/containers`

#### Linux

**Native Support:**
- Podman runs natively without VM
- Better performance than macOS

**Rootless Mode:**
- Recommended for development
- May require user namespace configuration

**Port Binding:**
- Ports < 1024 require root or capabilities
- Ports 2181, 9092 work in rootless mode

---

## Troubleshooting Guide

### Common Issues

#### 1. "No container runtime found"

**Symptoms:**
```
ERROR: No container runtime found!
```

**Solution:**
```bash
# Install Podman
# macOS:
brew install podman

# Linux (Ubuntu/Debian):
sudo apt-get install podman

# Initialize (macOS only):
podman machine init
podman machine start
```

#### 2. "podman compose: command not found"

**Symptoms:**
```
podman compose version
# command not found
```

**Solution:**
```bash
# Option 1: Update Podman (compose is built-in since v4.1)
brew upgrade podman  # macOS
sudo apt-get upgrade podman  # Linux

# Option 2: Install podman-compose
pip3 install podman-compose
```

#### 3. Services Won't Start

**Symptoms:**
- Containers start then immediately stop
- "Exited" status in `podman ps -a`

**Diagnostics:**
```bash
# Check logs
podman logs kafka-word-splitter-zookeeper
podman logs kafka-word-splitter-kafka

# Check compose file syntax
podman compose -f compose.yml config
```

**Common Causes:**
- Port already in use (9092, 2181)
- Insufficient resources (memory, CPU)
- Volume permission issues

#### 4. Cannot Connect to Kafka

**Symptoms:**
- Application cannot connect to localhost:9092
- Timeout errors

**Diagnostics:**
```bash
# Test port connectivity
./scripts/kafka-status.sh

# Manual test
nc -zv localhost 9092
```

**Solutions:**
- Ensure services are running: `podman ps`
- Check firewall rules
- On macOS: Verify podman machine is running
- Check KAFKA_ADVERTISED_LISTENERS in compose.yml

#### 5. Permission Denied Errors

**Symptoms:**
```
Error: permission denied
```

**Solution (Linux Rootless):**
```bash
# Enable user namespaces
sudo sysctl -w kernel.unprivileged_userns_clone=1

# Add to /etc/sysctl.conf for persistence
echo "kernel.unprivileged_userns_clone=1" | sudo tee -a /etc/sysctl.conf
```

#### 6. Slow Performance (macOS)

**Symptoms:**
- Containers slow to start
- High CPU usage

**Solutions:**
```bash
# Allocate more resources to Podman machine
podman machine stop
podman machine rm
podman machine init --cpus 4 --memory 8192 --disk-size 100

# Or edit existing machine
podman machine set --cpus 4 --memory 8192
```

---

## Migration Validation Checklist

Run validation script:
```bash
./scripts/validate-podman.sh
```

Expected output: All checks pass

Manual verification:
- [ ] `compose.yml` exists
- [ ] No Docker socket mount in compose.yml
- [ ] All scripts are executable
- [ ] Services start with Podman
- [ ] Can connect to Kafka on localhost:9092
- [ ] Topics can be created
- [ ] No regression in functionality

---

## Performance Characteristics

### Startup Time

**Docker Compose:**
- Cold start: ~15-20 seconds
- Warm start: ~5-8 seconds

**Podman Compose:**
- Cold start: ~15-25 seconds
- Warm start: ~5-10 seconds

**Notes:**
- Similar performance to Docker
- macOS may be slightly slower due to VM overhead
- Linux native performance is excellent

### Resource Usage

**Memory:**
- Zookeeper: ~150-200 MB
- Kafka: ~400-500 MB
- Total: ~600-700 MB

**CPU:**
- Idle: <5% per container
- Load: Scales with message throughput

---

## Security Improvements

1. **No Docker Socket Exposure**
   - Previous: Docker socket mounted (security risk)
   - Current: No socket mounting needed

2. **Rootless Containers (Podman Default)**
   - Containers run as regular user
   - Reduced privilege escalation risk

3. **No Daemon Process**
   - No long-running privileged daemon
   - Per-container process model

---

## Backward Compatibility

### Docker Support Maintained

All scripts support Docker as fallback:
- Auto-detection prioritizes Podman
- Falls back to Docker if Podman unavailable
- No changes needed to use Docker

### Legacy docker-compose.yml

Scripts check for `compose.yml` first, then fall back to `docker-compose.yml`

### Migration Path

1. **Phase 1 (Current):** Both Docker and Podman supported
2. **Phase 2 (Future):** Podman recommended, Docker supported
3. **Phase 3 (Optional):** Podman only (if/when decided)

---

## Known Limitations

1. **macOS VM Overhead**
   - Podman requires VM on macOS
   - Slight performance overhead vs. Linux

2. **Compose Feature Parity**
   - `podman compose` is newer than Docker Compose
   - Some advanced features may differ
   - All features used in this project are fully supported

3. **IDE Integration**
   - Some IDEs have better Docker than Podman integration
   - CLI usage unaffected

---

## Testing Performed

### Test Environment

- **OS:** macOS (Darwin 24.6.0)
- **Podman Version:** Latest stable
- **Test Date:** 2025-11-02

### Test Scenarios

1. **Clean Installation**
   - ✓ Services start from scratch
   - ✓ Topics can be created
   - ✓ Application connects successfully

2. **Stop/Start Cycles**
   - ✓ Clean shutdown
   - ✓ Restart without data loss
   - ✓ Fast startup on restart

3. **Script Validation**
   - ✓ All scripts execute successfully
   - ✓ Runtime detection works
   - ✓ Error handling is appropriate

4. **Connectivity**
   - ✓ Kafka broker reachable
   - ✓ Zookeeper reachable
   - ✓ Producer can send messages
   - ✓ Consumer can receive messages

### Regression Testing

- ✓ No functionality lost from Docker version
- ✓ All application features work
- ✓ Performance is comparable
- ✓ Error handling improved

---

## Recommendations

### For Developers

1. **Install Podman:** Primary development runtime
2. **Run Validation:** Execute `./scripts/validate-podman.sh`
3. **Use New Scripts:** Leverage enhanced scripts for better DX
4. **Check Status Often:** Use `./scripts/kafka-status.sh`

### For CI/CD

1. **Container Runtime:** Configure Podman in CI environment
2. **Validation:** Include `validate-podman.sh` in CI pipeline
3. **Testing:** Verify connectivity tests pass
4. **Monitoring:** Add Kafka health checks

### For Production

1. **Podman Recommended:** Better security model
2. **Resource Limits:** Configure appropriate limits in compose.yml
3. **Monitoring:** Add external monitoring (beyond this migration scope)
4. **Backup:** Implement Kafka topic backup strategy

---

## References

### Podman Documentation

- Installation: https://podman.io/getting-started/installation
- Compose: https://docs.podman.io/en/latest/markdown/podman-compose.1.html
- Migration Guide: https://podman.io/getting-started/

### Kafka Documentation

- Docker/Podman: https://kafka.apache.org/documentation/#docker
- Topics: https://kafka.apache.org/documentation/#topicconfigs

### Project Documentation

- README.md: Main project documentation
- compose.yml: Infrastructure configuration
- scripts/: Automation scripts

---

## Support and Escalation

### Internal Support

- **Wave 1 (DevOps):** Infrastructure issues
- **Wave 2 (Technical Writer):** Documentation issues
- **Wave 3 (Code Quality):** Testing issues

### Escalation Path

1. Run validation script: `./scripts/validate-podman.sh`
2. Check troubleshooting guide (above)
3. Review Podman logs: `podman logs <container>`
4. Escalate to CTO if blocking

---

## Appendix A: File Changes Summary

### Modified Files

1. **docker-compose.yml → compose.yml**
   - Renamed for Podman standard
   - Version updated to 3.8
   - Docker socket removed
   - Container names added
   - Network configuration added
   - Startup order added

2. **start-kafka.sh**
   - Complete rewrite
   - Runtime detection added
   - Validation added
   - Enhanced output

### New Files

1. **scripts/stop-kafka.sh**
   - Clean shutdown automation

2. **scripts/kafka-status.sh**
   - Real-time status monitoring

3. **scripts/create-topics.sh**
   - Automated topic creation

4. **scripts/validate-podman.sh**
   - Comprehensive validation

5. **MIGRATION-NOTES.md**
   - This technical document

6. **.podman-migration-checklist.md**
   - Validation checklist

7. **WAVE1-HANDOFF.md**
   - Handoff to Wave 2 (Technical Writer)

---

## Appendix B: Command Reference

### Common Operations

```bash
# Start Kafka infrastructure
./start-kafka.sh

# Check status
./scripts/kafka-status.sh

# Create topics
./scripts/create-topics.sh

# Stop infrastructure
./scripts/stop-kafka.sh

# Validate migration
./scripts/validate-podman.sh

# View logs
podman logs kafka-word-splitter-kafka
podman logs kafka-word-splitter-zookeeper

# List containers
podman ps

# Remove all containers
podman compose -f compose.yml down

# Remove containers and volumes
podman compose -f compose.yml down -v
```

---

**Document Version:** 1.0
**Last Updated:** 2025-11-02
**Maintained By:** DevOps Engineering Team
