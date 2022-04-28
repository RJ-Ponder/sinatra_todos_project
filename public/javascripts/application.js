/* global $ */

$(function () {
  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    
    var ok = confirm("Really? This cannot be undone!");
    if (ok) {
      // this.submit();
      
      var form = $(this);
      
      $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });
    }
  });
});