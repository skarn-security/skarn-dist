# Third-Party Notices

Skarn is distributed as a single statically linked binary. It incorporates the third-party components and adapted detection-rule patterns listed below. Each notice applies only to the referenced component or patterns, not to Skarn itself.

## PCRE2

- Project: https://github.com/PCRE2Project/pcre2
- License: BSD-3-Clause WITH PCRE2-exception
- Statically linked into the Skarn binary as the regular-expression engine for detection rules and session search.

```
Copyright (c) 1997-2007 University of Cambridge
Copyright (c) 2007-2024 Philip Hazel
All rights reserved.

PCRE2 Just-In-Time compilation support and the Stack-less Just-In-Time
compiler:
Copyright (c) 2009-2024 Zoltan Herczeg
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notices,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notices, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

* Neither the name of the University of Cambridge nor the names of any
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```

## SQLite

- Project: https://sqlite.org
- License: Public domain

The vendored SQLite amalgamation is compiled into the Skarn binary to read Cursor and VS Code session stores. SQLite is in the public domain and requires no license or attribution; it is listed here for completeness.

## Detection rules

Skarn's bundled community detection rules were adapted from the open-source secret-detection projects listed below. Their license terms require that the attribution and license text be retained in redistribution; they are reproduced here. These notices apply only to the detection-rule patterns adapted from each project, not to Skarn itself.

### gitleaks

- Project: https://github.com/gitleaks/gitleaks
- Copyright (c) 2019 Zachary Rice
- License: MIT

```
MIT License

Copyright (c) 2019 Zachary Rice

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Kingfisher

- Project: https://github.com/mongodb/kingfisher
- Copyright MongoDB, Inc.
- License: Apache License 2.0

### Titus

- Project: https://github.com/praetorian-inc/titus
- Copyright Praetorian, Inc.
- License: Apache License 2.0

### Apache License 2.0

The Kingfisher and Titus rule patterns are licensed under the Apache License, Version 2.0. You may obtain a copy of the License at:

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License. Rule patterns adapted from these projects have been modified for Skarn's detection engine.

### Upstream NOTICE attributions

Kingfisher and Titus each distribute a NOTICE file under Section 4(d) of the Apache License 2.0. The attributions in those files that pertain to rule patterns adapted into Skarn are reproduced below.

Titus's detection rules are derived from NoseyParker (https://github.com/praetorian-inc/noseyparker), licensed under the Apache License, Version 2.0. Certain rule patterns adapted from Kingfisher (among them the Firebase, Kubernetes, and Redis rules) are derived in part from Titus.

```
NoseyParker
Copyright 2023-2026 Praetorian Security, Inc.

This product includes software developed at Praetorian Security, Inc.
(https://www.praetorian.com/).

Licensed under the Apache License, Version 2.0.
```
