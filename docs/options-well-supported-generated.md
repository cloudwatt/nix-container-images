#### environment.etc

Set of files that have to be linked in <filename>/etc</filename>.


- type: `list or attribute set of submodules`
- default: `{}`


#### environment.etc.<name?>.enable

Whether this /etc file should be generated.  This
option allows specific /etc files to be disabled.


- type: `boolean`
- default: `true`


#### environment.etc.<name?>.gid

GID of created file. Only takes affect when the file is
copied (that is, the mode is not 'symlink').


- type: `signed integer`
- default: `0`


#### environment.etc.<name?>.group

Group name of created file.
Only takes affect when the file is copied (that is, the mode is not 'symlink').
Changing this option takes precedence over <literal>gid</literal>.


- type: `string`
- default: `+0`


#### environment.etc.<name?>.mode

If set to something else than <literal>symlink</literal>,
the file is copied instead of symlinked, with the given
file mode.


- type: `string`
- default: `symlink`


#### environment.etc.<name?>.source

Path of the source file.

- type: `path`
- default: `null`


#### environment.etc.<name?>.target

Name of symlink (relative to
<filename>/etc</filename>).  Defaults to the attribute
name.


- type: `string`
- default: `null`


#### environment.etc.<name?>.text

Text of the file.

- type: `null or strings concatenated with "\n"`
- default: `null`


#### environment.etc.<name?>.uid

UID of created file. Only takes affect when the file is
copied (that is, the mode is not 'symlink').


- type: `signed integer`
- default: `0`


#### environment.etc.<name?>.user

User name of created file.
Only takes affect when the file is copied (that is, the mode is not 'symlink').
Changing this option takes precedence over <literal>uid</literal>.


- type: `string`
- default: `+0`


#### environment.systemPackages

The set of packages that appear in
/run/current-system/sw.  These packages are
automatically available to all users, and are
automatically updated every time you rebuild the system
configuration.  (The latter is the main difference with
installing them in the default profile,
<filename>/nix/var/nix/profiles/default</filename>.


- type: `list of packages`
- default: `[]`


#### image.entryPoint

Entry point command list


- type: `list of strings`
- default: `[]`


#### image.env

Environment variables


- type: `attribute set`
- default: `{}`


#### image.from

The parent image


- type: `null or package`
- default: `null`


#### image.interactive

Add packages for an interactive use of the container
(bashInteractive, coreutils)


- type: `boolean`
- default: `false`


#### image.name

The name of the image


- type: `string`
- default: `null`


#### image.run

Extra commands run at container build time


- type: `strings concatenated with "\n"`
- default: ``


#### image.tag

The tag of the image


- type: `null or string`
- default: `null`


#### s6.init

The generated init script.

- type: `null or package`
- default: `null`


#### s6.services

Definition of s6 service.

- type: `attribute set of submodules`
- default: `{}`


#### s6.services.<name>.after

Configure ordering dependencies between units.

- type: `list of strings`
- default: `[]`


#### s6.services.<name>.enable

Whether to enable the service

- type: `boolean`
- default: `true`


#### s6.services.<name>.environment

Environment variables passed to the service's processes.

- type: `attribute set of null or string or path or packages`
- default: `{}`


#### s6.services.<name>.execLogger

Command executed as the service's logger: it gets the stdout of the main process.

- type: `null or string or package`
- default: `null`


#### s6.services.<name>.execStart

Command executed as the service's main process.

- type: `string or package`
- default: ``


#### s6.services.<name>.restartOnFailure

Restart the service if it fails. Note this is only used by long-run services.

- type: `boolean`
- default: `false`


#### s6.services.<name>.script

Shell commands executed as the service's main process.

- type: `strings concatenated with "\n"`
- default: ``


#### s6.services.<name>.type

Type of the s6 service (oneshot-pre, long-run or oneshot-post).

- type: `one of "long-run", "oneshot-pre", "oneshot-post"`
- default: `long-run`


#### s6.services.<name>.user

Set the UNIX user that the processes are executed as.

- type: `string`
- default: `root`


#### s6.services.<name>.workingDirectory

Sets the working directory for executed processes.

- type: `null or string`
- default: `null`


#### users.defaultUserShell

This option defines the default shell assigned to user
accounts. This can be either a full system path or a shell package.

This must not be a store path, since the path is
used outside the store (in particular in /etc/passwd).


- type: `path or package`
- default: `null`


#### users.enforceIdUniqueness

Whether to require that no two users/groups share the same uid/gid.


- type: `boolean`
- default: `true`


#### users.groups

Additional groups to be created automatically by the system.


- type: `list or attribute set of submodules`
- default: `{}`


#### users.groups.<name?>.gid

The group GID. If the GID is null, a free GID is picked on
activation.


- type: `null or signed integer`
- default: `null`


#### users.groups.<name?>.members

The user names of the group members, added to the
<literal>/etc/group</literal> file.


- type: `list of Concatenated strings`
- default: `[]`


#### users.groups.<name?>.name

The name of the group. If undefined, the name of the attribute set
will be used.


- type: `string`
- default: `null`


#### users.mutableUsers

If set to <literal>true</literal>, you are free to add new users and groups to the system
with the ordinary <literal>useradd</literal> and
<literal>groupadd</literal> commands. On system activation, the
existing contents of the <literal>/etc/passwd</literal> and
<literal>/etc/group</literal> files will be merged with the
contents generated from the <literal>users.users</literal> and
<literal>users.groups</literal> options.
The initial password for a user will be set
according to <literal>users.users</literal>, but existing passwords
will not be changed.

<warning><para>
If set to <literal>false</literal>, the contents of the user and
group files will simply be replaced on system activation. This also
holds for the user passwords; all changed
passwords will be reset according to the
<literal>users.users</literal> configuration on activation.
</para></warning>


- type: `boolean`
- default: `true`


#### users.users

Additional user accounts to be created automatically by the system.
This can also be used to set options for root.


- type: `list or attribute set of submodules`
- default: `{}`


#### users.users.<name?>.createHome

If true, the home directory will be created automatically. If this
option is true and the home directory already exists but is not
owned by the user, directory owner and group will be changed to
match the user.


- type: `boolean`
- default: `false`


#### users.users.<name?>.description

A short description of the user account, typically the
user's full name.  This is actually the “GECOS” or “comment”
field in <filename>/etc/passwd</filename>.


- type: `string`
- default: ``


#### users.users.<name?>.extraGroups

The user's auxiliary groups.

- type: `list of strings`
- default: `[]`


#### users.users.<name?>.group

The user's primary group.

- type: `string`
- default: `nogroup`


#### users.users.<name?>.hashedPassword

Specifies the hashed password for the user.
The options <option>hashedPassword</option>,
<option>password</option> and <option>passwordFile</option>
controls what password is set for the user.
<option>hashedPassword</option> overrides both
<option>password</option> and <option>passwordFile</option>.
<option>password</option> overrides <option>passwordFile</option>.
If none of these three options are set, no password is assigned to
the user, and the user will not be able to do password logins.
If the option <option>users.mutableUsers</option> is true, the
password defined in one of the three options will only be set when
the user is created for the first time. After that, you are free to
change the password with the ordinary user management commands. If
<option>users.mutableUsers</option> is false, you cannot change
user passwords, they will always be set according to the password
options.

To generate hashed password install <literal>mkpasswd</literal>
package and run <literal>mkpasswd -m sha-512</literal>.



- type: `null or string`
- default: `null`


#### users.users.<name?>.home

The user's home directory.

- type: `path`
- default: `/var/empty`


#### users.users.<name?>.initialHashedPassword

Specifies the initial hashed password for the user, i.e. the
hashed password assigned if the user does not already
exist. If <option>users.mutableUsers</option> is true, the
password can be changed subsequently using the
<command>passwd</command> command. Otherwise, it's
equivalent to setting the <option>hashedPassword</option> option.

To generate hashed password install <literal>mkpasswd</literal>
package and run <literal>mkpasswd -m sha-512</literal>.



- type: `null or string`
- default: `null`


#### users.users.<name?>.initialPassword

Specifies the initial password for the user, i.e. the
password assigned if the user does not already exist. If
<option>users.mutableUsers</option> is true, the password
can be changed subsequently using the
<command>passwd</command> command. Otherwise, it's
equivalent to setting the <option>password</option>
option. The same caveat applies: the password specified here
is world-readable in the Nix store, so it should only be
used for guest accounts or passwords that will be changed
promptly.


- type: `null or string`
- default: `null`


#### users.users.<name?>.isNormalUser

Indicates whether this is an account for a “real” user. This
automatically sets <option>group</option> to
<literal>users</literal>, <option>createHome</option> to
<literal>true</literal>, <option>home</option> to
<filename>/home/<replaceable>username</replaceable></filename>,
<option>useDefaultShell</option> to <literal>true</literal>,
and <option>isSystemUser</option> to
<literal>false</literal>.


- type: `boolean`
- default: `false`


#### users.users.<name?>.isSystemUser

Indicates if the user is a system user or not. This option
only has an effect if <option>uid</option> is
<option>null</option>, in which case it determines whether
the user's UID is allocated in the range for system users
(below 500) or in the range for normal users (starting at
1000).


- type: `boolean`
- default: `false`


#### users.users.<name?>.name

The name of the user account. If undefined, the name of the
attribute set will be used.


- type: `string`
- default: `null`


#### users.users.<name?>.packages

The set of packages that should be made availabe to the user.
This is in contrast to <option>environment.systemPackages</option>,
which adds packages to all users.


- type: `list of packages`
- default: `[]`


#### users.users.<name?>.password

Specifies the (clear text) password for the user.
Warning: do not set confidential information here
because it is world-readable in the Nix store. This option
should only be used for public accounts.
The options <option>hashedPassword</option>,
<option>password</option> and <option>passwordFile</option>
controls what password is set for the user.
<option>hashedPassword</option> overrides both
<option>password</option> and <option>passwordFile</option>.
<option>password</option> overrides <option>passwordFile</option>.
If none of these three options are set, no password is assigned to
the user, and the user will not be able to do password logins.
If the option <option>users.mutableUsers</option> is true, the
password defined in one of the three options will only be set when
the user is created for the first time. After that, you are free to
change the password with the ordinary user management commands. If
<option>users.mutableUsers</option> is false, you cannot change
user passwords, they will always be set according to the password
options.



- type: `null or string`
- default: `null`


#### users.users.<name?>.passwordFile

The full path to a file that contains the user's password. The password
file is read on each system activation. The file should contain
exactly one line, which should be the password in an encrypted form
that is suitable for the <literal>chpasswd -e</literal> command.
The options <option>hashedPassword</option>,
<option>password</option> and <option>passwordFile</option>
controls what password is set for the user.
<option>hashedPassword</option> overrides both
<option>password</option> and <option>passwordFile</option>.
<option>password</option> overrides <option>passwordFile</option>.
If none of these three options are set, no password is assigned to
the user, and the user will not be able to do password logins.
If the option <option>users.mutableUsers</option> is true, the
password defined in one of the three options will only be set when
the user is created for the first time. After that, you are free to
change the password with the ordinary user management commands. If
<option>users.mutableUsers</option> is false, you cannot change
user passwords, they will always be set according to the password
options.



- type: `null or Concatenated string`
- default: `null`


#### users.users.<name?>.shell

The path to the user's shell. Can use shell derivations,
like <literal>pkgs.bashInteractive</literal>. Don’t
forget to enable your shell in
<literal>programs</literal> if necessary,
like <code>programs.zsh.enable = true;</code>.


- type: `package or path`
- default: `pkgs.shadow`


#### users.users.<name?>.subGidRanges

Subordinate group ids that user is allowed to use.
They are set into <filename>/etc/subgid</filename> and are used
by <literal>newgidmap</literal> for user namespaces.


- type: `list of submodules`
- default: `[]`


#### users.users.<name?>.subGidRanges.*.count

Count of subordinate group ids

- type: `signed integer`
- default: `1`


#### users.users.<name?>.subGidRanges.*.startGid

Start of the range of subordinate group ids that user is
allowed to use.


- type: `signed integer`
- default: `null`


#### users.users.<name?>.subUidRanges

Subordinate user ids that user is allowed to use.
They are set into <filename>/etc/subuid</filename> and are used
by <literal>newuidmap</literal> for user namespaces.


- type: `list of submodules`
- default: `[]`


#### users.users.<name?>.subUidRanges.*.count

Count of subordinate user ids

- type: `signed integer`
- default: `1`


#### users.users.<name?>.subUidRanges.*.startUid

Start of the range of subordinate user ids that user is
allowed to use.


- type: `signed integer`
- default: `null`


#### users.users.<name?>.uid

The account UID. If the UID is null, a free UID is picked on
activation.


- type: `null or signed integer`
- default: `null`


#### users.users.<name?>.useDefaultShell

If true, the user's shell will be set to
<option>users.defaultUserShell</option>.


- type: `boolean`
- default: `false`


