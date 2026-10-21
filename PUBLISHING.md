# Publishing Human Made PHP images

This fork publishes selected PHP images to `docker.io/humanmade/php` independently
of Docker Official Images. The upstream CI continues to build and test the full
repository. The publishing workflow covers stable PHP 8.2–8.5 FPM images on Debian
Trixie or Bookworm, for Linux AMD64 and ARM64.

## Docker Hub setup

Create the `humanmade/php` repository on Docker Hub and provide a credential with
push access to it. In this GitHub repository's **Settings → Secrets and variables
→ Actions**, configure:

- Repository variable `DOCKERHUB_USERNAME`: the Docker Hub login for the credential.
- Repository secret `DOCKERHUB_TOKEN`: the Docker Hub access token.

Enable GitHub Actions in the fork if needed. Credentials are used only by the
manually triggered publishing workflow; pull request CI does not need them.

## Publish

1. Merge the desired PHP version changes into `master` and check that upstream CI
   and Verify Templating pass.
2. Open **Actions → Publish to Docker Hub → Run workflow** on `master`.
3. Choose a PHP series, or `all`, and a Debian suite. Defaults are all stable
   series and `trixie`, matching the current Altis WordPress base image suite.
4. Check the workflow's published tags in its job summaries.

The workflow runs only in `humanmade/php` on `master`. Each architecture is built
on a native runner and checked for the exact PHP version, valid FPM configuration,
and required bundled extensions. Architecture images are pushed by digest after
testing. Only after all builds pass are combined multi-platform tags created.

For example, PHP 8.5.12 on Trixie produces:

```text
humanmade/php:8.5.12-fpm-trixie
humanmade/php:8.5-fpm-trixie
```

No ambiguous `latest`, `8`, or suite-free tags are published. Re-running a version
can update both tags, including the patch tag, to incorporate base-image package
updates. Pin a digest in consumers that require an immutable reference. Publishing
runs for the same suite are serialized to avoid overlapping tag updates.

## Update PHP

Bring upstream security/version commits into this fork, including `versions.json`
and the generated Dockerfiles. For locally prepared version changes, use the
upstream `versions.sh` / `apply-templates.sh` process and retain source checksum
and signature verification. Review and run CI before publishing.

Consumers must explicitly change their base image from `php:<tag>` to
`humanmade/php:<tag>` and rebuild to use this fork. This workflow does not publish
or deploy downstream WordPress images.
