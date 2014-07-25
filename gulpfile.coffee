path = require 'path'
gulp = require 'gulp'
browserify = require 'gulp-browserify'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
header = require 'gulp-header'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
pkg = require path.join __dirname, 'package.json'

banner = [
    '/*!'
    '<%= pkg.name %> v<%= pkg.version %>'
    ' | @license <%= pkg.license %>'
    '*/'].join ' '
banner += '\n'

paths = 
  coffeescript: path.join '.', 'src', '**', '*.coffee'
  dist: path.join '.', 'dist'

gulp.task 'lint', ()->
  gulp.src(
    paths.coffeescript
  ).pipe(
    coffeelint()
  ).pipe(
    coffeelint.reporter 'fail'
  )

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

gulp.task 'default', ['compile']