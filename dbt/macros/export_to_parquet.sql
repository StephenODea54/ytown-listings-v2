{% macro export_to_parquet(directory) %}
    {% if execute %}
        {% do run_query("copy (select * from " ~ this ~ ") to '" ~ directory ~ "/" ~ this.identifier ~ ".parquet' (format parquet)") %}
    {% endif %}
{% endmacro %}
