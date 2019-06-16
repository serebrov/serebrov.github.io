---
title: CloudFront Setup to Route Requests to Services Based on Request Path
date: 2019-06-16
tags: aws
type: note
---

AWS CloudFront allows to have multiple origins for the distribution and, along with lambda@edge functions, that makes it possible to use CloudFront as an entry point to route the requests to different services based on the request path.

For example:

- www.myapp.com -> unbounce.com (landing pages)
- www.myapp.com/app -> single page app hosted on S3
- www.myapp.com/blog -> wordpress blog

<!-- more -->

# CloudFront Setup Structure

CloudFront [distribution](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview.html) can have one or more origins (sources to serve the data from) and one or more behaviors (rules defining how to cache the data based on the request path).

For example, we can have a distribution for a single-page app hosted on S3 (origin is S3 bucket) with one behavior defining caching rules.

Or we can have a distribution for a [wordpress site](https://aws.amazon.com/blogs/startups/how-to-accelerate-your-wordpress-site-with-amazon-cloudfront/) with one origin (wordpress server) and several behaviors defining caching rules for static and dynamic content.

The distribution has a unique default domain name (such as `d111111abcdef8.cloudfront.net`) and can also be assigned a custom domain name (such as `media.myapp.com`).

In a simple case that is enough: if we have multiple services (single-page app and wordpress blog), we can create separate distributions for them and use different sub-domains to route the requests (`app.myapp.com` and `blog.myapp.com`).

But it is also possible to merge different services under the same distribution and same domain name (`myapp.com/app` and `myapp.com/blog`) - this is the `multi-origin setup` described below.

# Multi-Origin CloudFront Setup

If we want to have a single domain name used for all services (frontend app, landing pages, wordpress blog, etc), we can achieve that with CloudFront by having multiple origins for each service (and multiple behaviors to specify which request paths should be forwarded to these origins).

The example setup for this post includes following origins:

- `www.myapp.com` -> unbounce.com, landing pages
- `www.myapp.com/app` -> single-page application, S3 bucket
- `www.myapp.com/blog` -> wordpress running on ElasticBeanstalk (origin points to Elastic Load Balancer)

As mentioned, CloudFront is able to route requests based on request path (this is defined in behaviors).

But there is also a bunch of additional problems to be solved with lambda@edge functions, such as:
- configure single-page application and wordpress to be run from the subfolders
- handle requests without the trailing slash (`www.myapp.com/app` vs `www.myapp.com/app/`
= handle default `index.html` object for a sub-folder on S3.

The solutions for these problems are described below, in the following sections of this post.

For this setup, we have the following origins:

- 0: app*, origin: S3-app.myapp.com
- 1: blog/wp-login.php, origin: wordpress-elb
- 2: blog/wp-admin/*, origin: wordpress-elb
- 3: blog/wp-includes/*, origin: S3-wordpress.myapp.com
- 4: blog/wp-content/*, origin: S3-wordpress.myapp.com
- 5: blog*, origin: wordpress-elb
- 6: Default (*), origin: unbounce-www.myapp.com

The `app*` behavior serves the single-page application from the S3 origin.
The app is accessible from the sub-path (`myapp.com/app`) and should be placed in the sub-folder on S3 (the sub-path is preserved in the request to origin).

We use helper lambda functions to forward all requests to `index.html`:

- Origin Request: CloudFrontSubdirectoryIndex - catches root requests (`www.myapp.com/app`) and forwards them to `index.html`
- Origin Response: CloudFrontDefaultIndexForOrigin - catches 404 / 403 requests (`www.myapp.com/app/some-path`) and forwards them to `index.html`

More details and lambda functions code are below.

The `blog...` group of behaviors forward `/blog/...` requests to the wordpress origin. 

There are special behaviors for `wp-login.php` and `wp-admin/*` as these are used for administrative tasks and here we don't need caching and special behaviors for `wp-includes/*` and `wp-content/*` - these are forwarded to S3.

For the `blog*` behaviors we also have the `CloudFrontRedirectToTrailingSlash` lambda function attached to the "Viewer Request" event that forwards `www.myapp.com/blog` requests to `www.myapp.com/blog/`.

The default origin forwards root requests (www.myapp.com/) to unbounce.com landing pages.

# Unbounce Setup

Unbounce.com is a service for landing pages and there are two (official) ways to use it: point CNAME (such as `www.myapp.com`) to unbounce.com or use a wordpress plugin - in this case the "Host" header should contain the domain name (`www.myapp.com`).

We can use the latter to make unbounce work with CloudFront: we setup the `www.myapp.com` domain to point to CloudFront and we configure CloudFront to forward the `Host` header to unbounce.

The configuration sequence I used is this:

  1. Add www.myapp.com domain on unbounce.com
  2. Get the unbounce URL, like `ab44444888888.unbouncepages.com`
  3. In DNS settings, point `www` CNAME to `ab44444888888.unbouncepages.com`
  4. Wait until unbounce shows "Working and Secure" for the domain
  5. Edit (or create) CloudFront distribution, set alternative domain to www.myapp.com (or see https://serverfault.com/a/888776/527019, there is also a method based on lambda function)
  6. Create the CloudFront origin, point it to unbounce URL (`ab44444888888.unbouncepages.com`)
  7. Create default behavior `(*)` for the origin above, disable caching (set "Cache Based on Selected Request Headers" to "All")
  8. Change DNS settings, point `www` subdomain to CloudFront distribution (`d33xxx8888xxxx.cloudfront.net`) - replace the unbounce domain with CloudFront domain
  9. Wait for DNS changes to propagate, now the www.myapp.com root URL should point to CloudFront

So we first point CNAME to unbounce.com, wait until unbounce thinks that everything is good and then reconfigure the CNAME to point to CloudFront (and CloudFront forwards the custom domain name via Host header).

# Single Page App Setup

The single page app setup is pretty simple with CloudFront: the app source is copied to S3 bucket and then served via CloudFront (the origin is S3 bucket, with one default behavior).

Example shell script to deploy the SPA application to S3 (also sends Slack notification about the deployment):

```
#!/usr/bin/env bash

SCRIPT_PATH=`dirname $0`
ROOT_PATH=$SCRIPT_PATH/../

SLACK_HOOK=https://hooks.slack.com/services/THANKFT88/BBB44444D/aarrrvRRxxxxxSSSSSjjHHHH
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ $APP_ENV == "develop" ]]; then
    CLOUDFRONT_DISTRIBUTION=EEE88888888888
    AWS_BUCKET=dev.myapp.com
elif [[ $APP_ENV == "production" ]]; then
    CLOUDFRONT_DISTRIBUTION=EEE9999999999
    AWS_BUCKET=app.myapp.com
else
    echo "Unknown environment ${APP_ENV}"
    exit 1
fi

echo "Deploying ${GIT_BRANCH} to ${AWS_BUCKET}"

. ${SCRIPT_PATH}/deploy_aws.sh

if [ $? -eq 0 ]; then
    echo 'Deployment: OK'
    curl -s -X POST $SLACK_HOOK \
    -H "content-type:application/json" \
    -d '{"text":"[frontend] Branch `'"${GIT_BRANCH}"'` was successfully deployed to `'"${AWS_BUCKET}"'` bucket."}'
else
    echo 'Deployment: FAILED'
    exit $?
    curl -s -X POST $SLACK_HOOK \
    -H "content-type:application/json" \
    -d '{"text":"[frontend] Branch `'"${GIT_BRANCH}"'` deployment to `'"${AWS_BUCKET}"'` bucket FAILED."}'
fi

```

And the `deploy_aws.sh` script:

```
#!/usr/bin/env bash
set -e

SCRIPT_PATH=`dirname $0`
ROOT_PATH=$SCRIPT_PATH/../
RELEASE=$(git rev-parse HEAD)

# Expected environment variables
# AWS_BUCKET:=dev.myapp.com
# CLOUDFRONT_DISTRIBUTION:=YYY
# AWS_CLI_OPTS - optional, can be used to set profile

echo "Syncing dist to ${AWS_BUCKET} with options ${AWS_CLI_OPTS}"

aws s3 sync --delete dist/ s3://${AWS_BUCKET}/app/ ${AWS_CLI_OPTS}

# Invalidate app on CloudFront
aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_DISTRIBUTION} --paths /app/* ${AWS_CLI_OPTS}
```

I've used such a setup for Angular and Vue applications, it should work well for other frameworks too.

In a single-origin setup, it is also useful to:

- Set default object for distribution to `index.html`
- Add 404 and 403 error handlers for distribution and reply 200 OK and with `index.html` (so all requests are sent to the single page app even if there are no real files on S3)

Unfortunately, these settings are on the distribution level, although it would be more useful to have them for behaviors: in a multi-origin setup, we need to have same configuration, but only for a specific request path (for example, for `www.myapp.com/app`, but not for `www.myapp.com/blog`).

So in multi-origin setup the solution is to use lambda@edge functions (described below) to do the same - use `index.html` as default object (CloudFrontSubdirectoryIndex) and redirect requests to non-existing files to `index.html` (CloudFrontDefaultIndexForOrigin).

# WordPress Setup

WordPress can be either installed on a standalone EC2 instance, hosted externally or running on ElasticBeanstalk, the CloudFront setup will be similar:

- One origin that points to the wordpress server
- Several behaviors (described above, see `blog...` group) to describe caching rules for the static and dynamic content.

I am hosting WordPress on ElasticBeanstalk which has several nuances related to how WordPress works.

Since we use Elastic Beanstalk as a deployment platform (in general, this is also true if we host on stand-alone EC2), we should treat underlying EC2 instance and it's file storage as a disposable resource.

We can use W3 Total Cache plugin (or other) to move variable content to S3 (for example, `wp.myapp.com` bucket) and serve via CDN (add a distribution for `wp.myapp.com` domain).

To deploy the WordPress to S3 we create a repository with WordPress code, do the 
 configuration changes, plugin or theme installs that affect the code (such as wp-config.php) and deploy to ElasticBeanstalk. 
 Note that these changes should only be done locally, committed to git and deployed (not configured directly on the live server as these changes may be lost).

Here are some useful resources describing the WordPress setup options on AWS:

- Using this for the current setup: https://d0.awsstatic.com/whitepapers/deploying-wordpress-with-aws-elastic-beanstalk.pdf
- How to accelerate your WordPress site with Amazon CloudFront: https://aws.amazon.com/blogs/startups/how-to-accelerate-your-wordpress-site-with-amazon-cloudfront/
- W3 Total Cache plugin: https://wordpress.org/plugins/w3-total-cache/
- https://d0.awsstatic.com/whitepapers/wordpress-best-practices-on-aws.pdf
- How to accelerate your WordPress site with Amazon CloudFront | AWS Startups Blog: https://aws.amazon.com/blogs/startups/how-to-accelerate-your-wordpress-site-with-amazon-cloudfront/
- (example with EFS) Deploying a High-Availability WordPress Website with an External Amazon RDS Database to Elastic Beanstalk - AWS Elastic Beanstalk: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/php-hawordpress-tutorial.html, https://github.com/aws-samples/eb-php-wordpress/
- Hosting WordPress on AWS: https://github.com/aws-samples/aws-refarch-wordpress

**Elastic Beanstalk Setup for PHP App**

The (standard) Elastic Beanstalk setup for php is a set of configurations and scripts that automatically deploys and runs the application on the EC2 instance:

- The app is deployed to `/var/www/html` and handled by apache
- Apache logs are under `/var/log/httpd` (logs are also sent to CloudWatch)
- System log is `/var/log/messages`

Note: along with the application code it is useful to also deploy `.git` folder (don't add it to `.ebignore`), so `git status` on the server inside the `/var/www/html` will show if there are any modifications done directly on the server.
This is useful to check if there are any local changes to the files after changing wordpress settings (if there are changes, we need to copy them back to local machine, commit to git and redeploy).

# Single Page App Setup: Function To Handle Index Documents in Subfolders (CloudFrontDefaultIndexForOrigin)

For multi-origin setup, we use CloudFront distribution to route the requests to multiple origins depending on the request path.

In this case the application on S3 also needs to be in the sub-folder (`my-bucket/app`).
And it means that we lose the ability to redirect failing requests to `index.html` (this only works in the root folder), so if we go to the url `www.myapp.com/app/login`, it will end up with a 404 error.

In a single-origin CloudFront distribution this issue can be solved by setting the default object for the distribution to `index.html` and also adding "Error pages" for 404 and 403 that would also point to `index.html`.

For a "mutli-origin" setup a solution is to add lambda@edge function for the "Origin Response" event and replace 403 / 404 errors with `index.html` content.

The Lambda function code ([source](https://andrewlock.net/using-lambda-at-edge-to-handle-angular-client-side-routing-with-s3-and-cloudfront/)) looks like this:

```
'use strict';

// Source - https://andrewlock.net/using-lambda-at-edge-to-handle-angular-client-side-routing-with-s3-and-cloudfront/

const http = require('https');

const indexPage = 'index.html';

exports.handler = async (event, context, callback) => {
    const cf = event.Records[0].cf;
    const request = cf.request;
    const response = cf.response;
    const statusCode = response.status;

    // Only replace 403 and 404 requests typically received
    // when loading a page for a SPA that uses client-side routing
    const doReplace = request.method === 'GET'
                    && (statusCode == '403' || statusCode == '404');

    const result = doReplace 
        ? await generateResponseAndLog(cf, request, indexPage, response)
        : response;

    callback(null, result);
};

async function generateResponseAndLog(cf, request, indexPage, originalResponse){

    const domain = cf.config.distributionDomainName;
    const appPath = getAppPath(request.uri);

    const indexPath = `/${appPath}/${indexPage}`;

    const response = await generateResponse(domain, indexPath, request, originalResponse);
    // console.log('response: ' + JSON.stringify(response));
    return response;
}

async function generateResponse(domain, path, request, originalResponse){
    try {
        // Load HTML index from the CloudFront cache
        const s3Response = await httpGet({ hostname: domain, path: path });

        const headers = s3Response.headers || 
            {
                'content-type': [{ value: 'text/html;charset=UTF-8' }]
            };

        const responseHeaders = wrapAndFilterHeaders(headers, originalResponse.headers || {})

        // Debug headers to see the original requested URL vs the index file request.
        // responseHeaders['x-lambda-request-uri'] = [{value: request.uri}]
        // responseHeaders['x-lambda-hostname'] = [{value: domain}]
        // responseHeaders['x-lambda-path'] = [{value: path}]
        // responseHeaders['x-lambda-response-status'] = [{value: String(s3Response.status)}]

        return {
            status: '200',
            headers: responseHeaders,
            body: s3Response.body
        };
    } catch (error) {
        console.log(error)
        return {
            status: '500',
            headers:{
                'content-type': [{ value: 'text/plain' }]
            },
            body: 'An error occurred loading the page'
        };
    }
}

function httpGet(params) {
    return new Promise((resolve, reject) => {
        http.get(params, (resp) => {
            console.log(`Fetching ${params.hostname}${params.path}, status code : ${resp.statusCode}`);
            let result = {
                status: resp.statusCode,
                headers: resp.headers,
                body: ''
            };
            resp.on('data', (chunk) => { result.body += chunk; });
            resp.on('end', () => { resolve(result); });
        }).on('error', (err) => {
            console.log(`Couldn't fetch ${params.hostname}${params.path} : ${err.message}`);
            reject(err, null);
        });
    });
}

// Get the app path segment e.g. candidates.app, employers.client etc
function getAppPath(path){
    if(!path){
        return '';
    }

    if(path[0] === '/'){
        path = path.slice(1);
    }

    const segments = path.split('/');

    // will always have at least one segment (may be empty)
    return segments[0];
}

// Cloudfront requires header values to be wrapped in an array
function wrapAndFilterHeaders(headers, originalHeaders){
    const allowedHeaders = [
        'content-type',
        'content-length',
        'last-modified',
        'date',
        'etag'
    ];

    const responseHeaders = originalHeaders;

    if(!headers){
        return responseHeaders;
    }

    for(var propName in headers) {
        // only include allowed headers
        if(allowedHeaders.includes(propName.toLowerCase())){
            var header = headers[propName];

            if (Array.isArray(header)){
                // assume already 'wrapped' format
                responseHeaders[propName] = header;
            } else {
                // fix to required format
                responseHeaders[propName] = [{ value: header }];
            }    
        }

    }

    return responseHeaders;
}
```

# Wordpress: Handle Trailing Slash - Function To Redirect "/blog" Requests (CloudFrontRedirectToTrailingSlash)

This is used to redirect `www.myapp.com/blog` requests to `www.myapp.com/blog/` (add trailing slash which triggers index.php loading from the folder):

The Lambda function code ([source](https://www.barelyknown.com/posts/add-trailing-slash-to-cloudfront-request)):

```
const path = require('path');
exports.handler = async (event) => {
  const { request } = event.Records[0].cf;
  const { uri } = request;
  const extension = path.extname(uri);
  if (extension && extension.length > 0) {
    return request;
  }
  const last_character = uri.slice(-1);
  if (last_character === "/") {
    return request;
  }
  const newUri = `${uri}/`;
  console.log(`Rewriting ${uri} to ${newUri}...`);
  request.uri = newUri;
  return request;
};
```

The function is attached to "Viewer Request" event.

# Function to Handle S3 Directory Requests (CloudFrontSubdirectoryIndex)

This function is attached to the "Origin Request" event and it handles requests like `www.myapp.com/app/` (with trailing slash at the end).

By default this request returns `200 OK` with `application/x-directory` content type and empty body.

The Lambda function adds `index.html` to these requests (so the request becomes `www.myapp.com/app/index.html`).

The lambda function code ([source](https://aws.amazon.com/blogs/compute/implementing-default-directory-indexes-in-amazon-s3-backed-amazon-cloudfront-origins-using-lambdaedge/)):

```
'use strict';

// Source: https://aws.amazon.com/blogs/compute/implementing-default-directory-indexes-in-amazon-s3-backed-amazon-cloudfront-origins-using-lambdaedge/
//
// Handles requests like www.myapp.com/app/ (with trailing slash) and adds index.html to them
// By default this request returns 200 OK with application/x-directory content type
exports.handler = (event, context, callback) => {

    // Extract the request from the CloudFront event that is sent to Lambda@Edge 
    var request = event.Records[0].cf.request;

    // Extract the URI from the request
    var olduri = request.uri;

    // Match any '/' that occurs at the end of a URI. Replace it with a default index
    var newuri = olduri.replace(/\/$/, '\/index.html');

    // Log the URI as received by CloudFront and the new URI to be used to fetch from origin
    console.log("Old URI: " + olduri);
    console.log("New URI: " + newuri);

    // Replace the received URI with the URI that includes the index page
    request.uri = newuri;

    // Return to CloudFront
    return callback(null, request);
};
```

# Function to Redirect CloudFront Requests (CloudFrontRedirectApp)

This can be useful to transfer the application from single-origin setup to multi-rigin.
In this case, the `app.myapp.com` requests should be forwared to `www.myapp.com/app`.

Note: in the next section there is another solution for the same problem, based on S3 static website hosting feature.

With Lambda function, the redirect can be done by attaching a function to the old CloudFront distribution behavior, the "Viewer Request" event:

```
const path = require('path');
exports.handler = async (event) => {
  const { request } = event.Records[0].cf;
  const { uri } = request;
  const newUri = `https://www.myapp.com/app${uri}`;
  console.log(`Rewriting ${uri} to ${newUri}...`);

  let responseHeaders = {
      location: [{
          key: 'Location',
          value: newUri,
      }],
  }
  // Debug headers to see the original requested URL vs the index file request.
  responseHeaders['x-lambda-request-uri'] = [{value: request.uri}]
  responseHeaders['x-lambda-redirect-url'] = [{value: newUri}]

  /*
   * Generate HTTP redirect response with 302 status code and Location header.
   */
  const response = {
      status: '302',
      statusDescription: 'Found',
      headers: responseHeaders,
  };
  return response;
};

```

# Redirect Requests to the new Location with S3 Static Website

This is another solution to the problem described above: redirect requests from the old location (such as `app.myapp.com` to new `www.myapp.com/www`).

This method is described in [AWS docs](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/tutorial-redirecting-dns-queries.html).

The initial setup is this:

- The `app.myapp.com` points to S3 bucket (root), there is CloudFront distribution using it as origin
- The `www.myapp.com/app` points to S3 bucket (`/app` subfolder), there is (another) CloudFront distribution using it as origin

The redirect can be configured like this:

- Create S3 bucket `app.myapp.com-old.app` (can be empty)
- Enable static website hosting for this bucket
- Select "Redirect requests" option
- Set "Target bucket or domain" to `www.myapp.com/app`
- Set "Protocol" to `https`
- Copy public URL for the bucket (develop.myapp.com-old.app.s3-website-us-east-1.amazonaws.com)
- Edit the CloudFront distribution for `app.myapp.com`, change origin source to public URL for the new bucket

Now all requests to `app.myapp.com` should be redirected to `www.myapp.com/app`.
