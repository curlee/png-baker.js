# Gulpfile
------

Require some libs.

    path = require 'path'
    gulp = require 'gulp'
    browserify = require 'gulp-browserify'
    coffee = require 'gulp-coffee'
    coffeelint = require 'gulp-coffeelint'
    header = require 'gulp-header'
    rename = require 'gulp-rename'
    uglify = require 'gulp-uglify'
    pkg = require path.join __dirname, 'package.json'

Create the banner for insertion in headers.

    banner = [
        '/*!'
        '<%= pkg.name %> v<%= pkg.version %>'
        ' | @license <%= pkg.license %>'
        '*/'].join ' '
    banner += '\n'

Set up paths.

    paths =
      coffeescript: path.join '.', 'src', '**', '*.litcoffee'
      dist: path.join '.', 'dist'

## lint
-----

Run lint on coffeescript files.

    gulp.task 'lint', ()->
      gulp.src(
        paths.coffeescript
      ).pipe(
        coffeelint()
      ).pipe(
        coffeelint.reporter 'fail'
      )

## compile
-----

Call `lint`, then compile coffeescript to JS.

    gulp.task 'compile', ['lint'], ()->
      return gulp.src(
        paths.coffeescript
      ).pipe(
        coffee()
      ).pipe(
        header banner, { pkg: pkg }
      ).pipe(
        rename "png-baker.min.js"
      ).pipe(
        gulp.dest paths.dist
      )

## default
-----

Default gulp task. Calls `compile`.

    gulp.task 'default', ['compile']