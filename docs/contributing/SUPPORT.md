# Support

Need help with Kafka Word Splitter? This document will guide you to the right resources.

## Getting Help

### Before Asking for Help

1. **Check the Documentation**
   - [README.md](README.md) - Project overview
   - [QUICK_START.md](QUICK_START.md) - Getting started guide
   - [BUILD.md](BUILD.md) - Build instructions
   - [ARCHITECTURE_REPORT.md](ARCHITECTURE_REPORT.md) - Architecture details
   - [SHUTDOWN.md](SHUTDOWN.md) - Shutdown procedures

2. **Search Existing Issues**
   - [Open Issues](https://github.com/strawberry-code/kafka-word-splitter/issues)
   - [Closed Issues](https://github.com/strawberry-code/kafka-word-splitter/issues?q=is%3Aissue+is%3Aclosed)
   - Your question may already be answered

3. **Review Common Issues**
   - See [Common Problems](#common-problems) section below

## Support Channels

### GitHub Issues

**For:** Bug reports, feature requests, technical problems

**How to Use:**
1. Go to [Issues](https://github.com/strawberry-code/kafka-word-splitter/issues)
2. Click "New Issue"
3. Choose appropriate template:
   - Bug Report
   - Feature Request
   - Question
4. Fill out template completely
5. Add relevant labels

**Response Time:** 1-3 business days

[Create an Issue](https://github.com/strawberry-code/kafka-word-splitter/issues/new)

---

### GitHub Discussions

**For:** General questions, ideas, community discussions

**How to Use:**
1. Go to [Discussions](https://github.com/strawberry-code/kafka-word-splitter/discussions)
2. Click "New Discussion"
3. Choose category:
   - Q&A (Questions)
   - Ideas (Feature ideas)
   - Show and Tell (Share your projects)
   - General

**Response Time:** Best effort, community-driven

[Start a Discussion](https://github.com/strawberry-code/kafka-word-splitter/discussions/new)

---

### Stack Overflow

**For:** Coding questions, implementation help

**How to Use:**
1. Search for existing questions tagged `kafka-word-splitter` or `apache-kafka`
2. If not found, ask a new question
3. Tag with: `kafka`, `java`, `apache-kafka`, `kafka-word-splitter`

**Tips:**
- Provide minimal reproducible example
- Include error messages
- Share relevant code snippets
- Mention your environment (OS, Java version, etc.)

[Search Stack Overflow](https://stackoverflow.com/questions/tagged/apache-kafka)

---

## How to Ask Good Questions

### Provide Context

Help others help you by including:

1. **What you're trying to do**
   - Goal or desired outcome
   - Use case description

2. **What you've tried**
   - Steps you've taken
   - Commands you've run
   - Configuration changes made

3. **What went wrong**
   - Exact error messages
   - Unexpected behavior
   - Log output

4. **Your environment**
   - Operating system
   - Java version
   - Project version/commit
   - Docker version (if relevant)

### Example Good Question

```
I'm trying to run the producer but it fails to connect to Kafka.

Environment:
- OS: Ubuntu 22.04
- Java: OpenJDK 17.0.2
- Project: main branch (commit abc123)
- Docker: 24.0.5

Steps to reproduce:
1. Started Kafka: docker-compose up -d
2. Verified Kafka running: docker ps shows kafka container
3. Built project: ./gradlew clean build (successful)
4. Ran producer: java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar org.example.ProducerApp /tmp/watch

Error message:
org.apache.kafka.common.errors.TimeoutException: Failed to update metadata after 60000 ms.

What I've tried:
- Verified port 9092 is open: nc -zv localhost 9092 (successful)
- Checked Kafka logs: docker-compose logs kafka (no errors)
- Tried different directory: same error

Am I missing a configuration step?
```

### Example Bad Question

```
It doesn't work. Help!
```

This lacks:
- What "it" is
- What "doesn't work" means
- Environment details
- Steps to reproduce
- Error messages

---

## Common Problems

### Build Issues

#### Problem: "Permission denied: ./gradlew"
**Solution:**
```bash
chmod +x gradlew
./gradlew build
```

#### Problem: "No such file: gradle-wrapper.jar"
**Solution:**
Wrapper jar might be missing. Re-download:
```bash
gradle wrapper
```

#### Problem: "Unsupported class file major version"
**Solution:**
Java version mismatch. Project requires Java 17+:
```bash
java -version  # Check version
# Install Java 17 if needed
```

#### Problem: Build fails with dependency errors
**Solution:**
Clear Gradle cache and retry:
```bash
./gradlew clean --refresh-dependencies
./gradlew build
```

---

### Kafka Issues

#### Problem: "Connection to localhost:9092 refused"
**Solution:**
Kafka not running or not ready:
```bash
# Check Kafka status
docker ps

# Restart Kafka
docker-compose down
docker-compose up -d

# Wait for Kafka to be ready (10-30 seconds)
sleep 15
nc -zv localhost 9092
```

#### Problem: "Topic not found"
**Solution:**
Create missing topics:
```bash
KAFKA_CONTAINER=$(docker ps --filter "name=kafka" -q)
for i in {3..10}; do
  docker exec -it $KAFKA_CONTAINER \
    kafka-topics --create --topic $i --bootstrap-server localhost:9092
done
```

#### Problem: Producer sends messages but consumer doesn't receive
**Solution:**
Check topic mismatch:
```bash
# List topics
docker exec -it $(docker ps --filter "name=kafka" -q) \
  kafka-topics --list --bootstrap-server localhost:9092

# Verify consumer is subscribed to correct topic
# Example: 5-letter words go to topic "5"
```

#### Problem: "Port 9092 already in use"
**Solution:**
Another Kafka instance is running:
```bash
# Find what's using port 9092
lsof -i :9092

# Stop conflicting service
# Or change port in docker-compose.yml
```

---

### Runtime Issues

#### Problem: Application doesn't shut down with Ctrl+C
**Solution:**
Force shutdown:
```bash
# Find process ID
ps aux | grep kafka-word-splitter

# Kill process
kill -9 <pid>
```

If this happens frequently, please report a bug.

#### Problem: Out of memory errors
**Solution:**
Increase JVM memory:
```bash
java -Xmx2g -jar build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
  org.example.ProducerApp /path/to/watch
```

#### Problem: Consumer creates empty output file
**Solution:**
No messages in topic yet. Verify:
```bash
# Check if producer is sending messages
# Check producer logs for "Sent word" messages

# Manually produce test message
docker exec -it $(docker ps --filter "name=kafka" -q) \
  kafka-console-producer --topic 5 --bootstrap-server localhost:9092
# Type a word and press Enter
```

---

### Docker Issues

#### Problem: Docker daemon not running
**Solution:**
```bash
# macOS/Windows: Start Docker Desktop

# Linux: Start Docker service
sudo systemctl start docker
```

#### Problem: Container name conflicts
**Solution:**
```bash
# Remove old containers
docker-compose down
docker rm $(docker ps -aq)

# Restart
docker-compose up -d
```

#### Problem: Cannot connect to Docker daemon
**Solution:**
```bash
# Check Docker is running
docker info

# On Linux, add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

---

## Security Issues

**IMPORTANT:** Do NOT open public issues for security vulnerabilities.

### Reporting Security Vulnerabilities

If you discover a security vulnerability:

1. **Email:** security@example.com (configure this)
2. **GitHub:** Use [Security Advisories](https://github.com/strawberry-code/kafka-word-splitter/security/advisories/new)

**Include:**
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

**Response Time:** 24-48 hours for acknowledgment

We take security seriously and will work with you to address the issue before public disclosure.

See [SECURITY.md](SECURITY.md) for our security policy.

---

## Feature Requests

Have an idea for a new feature?

### Before Requesting

1. **Check existing requests**
   - [Feature label](https://github.com/strawberry-code/kafka-word-splitter/labels/feature)
   - [Discussions - Ideas](https://github.com/strawberry-code/kafka-word-splitter/discussions/categories/ideas)

2. **Consider if it fits project scope**
   - Is it related to Kafka and file processing?
   - Would it benefit other users?
   - Can it be implemented as a plugin/extension?

### How to Request

1. **Open an issue** with "Feature Request" template
2. **Describe the problem** you're trying to solve
3. **Propose a solution** (optional)
4. **Consider alternatives** and trade-offs
5. **Be open to discussion** and feedback

**Example:**
```
Feature: Add support for JSON file parsing

Problem:
Currently only plain text files are supported. Many users have JSON logs
they want to process.

Proposed Solution:
- Add JSON parser using Jackson library
- Extract specific fields as "words"
- Route to topics based on field value

Alternatives:
- Preprocess JSON to text externally
- Use separate JSON-specific tool

Benefits:
- Native JSON support
- More flexible data routing
- Common use case
```

---

## Contributing

Want to contribute code, documentation, or tests?

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Code style guidelines
- Testing requirements
- Pull request process

---

## Documentation Feedback

Found an error in documentation? Have a suggestion?

**For documentation issues:**
1. [Open an issue](https://github.com/strawberry-code/kafka-word-splitter/issues/new)
2. Label: "documentation"
3. Specify which file and what's wrong/missing
4. Suggest improvement if possible

**Quick fixes:**
You can also submit a PR directly for:
- Typos
- Broken links
- Formatting issues
- Minor clarifications

---

## Community Guidelines

### Be Respectful

- Treat others with respect and kindness
- Be constructive in feedback
- Assume good intentions
- Welcome newcomers

### Be Patient

- Maintainers are volunteers
- Responses may take time
- Not all features can be implemented
- Some issues may not be reproducible

### Be Helpful

- Share your solutions
- Help others in discussions
- Improve documentation
- Report bugs clearly

---

## Response Times

| Channel | Response Time | Who Responds |
|---------|---------------|--------------|
| GitHub Issues (bugs) | 1-3 business days | Maintainers |
| GitHub Issues (features) | 3-7 business days | Maintainers |
| GitHub Discussions | Best effort | Community + maintainers |
| Security reports | 24-48 hours | Maintainers |
| Pull requests | 3-7 business days | Maintainers |

These are target response times, not guarantees. We'll do our best!

---

## Additional Resources

### Documentation
- [README.md](README.md) - Start here
- [QUICK_START.md](QUICK_START.md) - Fast setup
- [BUILD.md](BUILD.md) - Build guide
- [ARCHITECTURE_REPORT.md](ARCHITECTURE_REPORT.md) - Architecture
- [SHUTDOWN.md](SHUTDOWN.md) - Shutdown behavior
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - File organization

### External Resources
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Kafka Quickstart](https://kafka.apache.org/quickstart)
- [Gradle User Guide](https://docs.gradle.org/current/userguide/userguide.html)
- [Java 17 Documentation](https://docs.oracle.com/en/java/javase/17/)

### Community
- [Apache Kafka Users Mailing List](https://kafka.apache.org/contact)
- [Kafka on Stack Overflow](https://stackoverflow.com/questions/tagged/apache-kafka)
- [Confluent Community](https://www.confluent.io/community/)

---

## Maintainers

This project is maintained by:
- **Strawberry Code Team**
- Contact: Via GitHub issues or discussions

---

## Legal

### License
This project is licensed under the [MIT License](LICENSE).

### Code of Conduct
We follow standard open source community guidelines. Be respectful, constructive, and welcoming.

---

## Still Need Help?

If you've:
- Read the documentation
- Searched existing issues
- Tried the solutions above
- Still have a problem

Then please:
1. [Open a new issue](https://github.com/strawberry-code/kafka-word-splitter/issues/new)
2. Provide all requested information
3. Be as specific as possible

We're here to help!

---

**Thank you for using Kafka Word Splitter!**
