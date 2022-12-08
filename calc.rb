require 'logger'
require 'optparse'
require 'strscan'

class CALC
    Keywords = {
        "+" => :add,
        "-" => :sub,
        "*" => :mul,
        "/" => :div,
        "(" => :left_parn,
        ")" => :right_parn,
    }

    # 式    : 項 (( '+' | '-' ) 項 )*
    # 項    : 因子 (( '*' | '/' ) 因子 )*
    # 因子  : '-'? (リテラル / '(' 式 ')')

    # インスタンス化時に実行される
    def initialize
        buffer = nil

        # ログ出力用
        @logger = Logger.new(STDOUT)
        ## リリース用レベル
        @logger.level = Logger::WARN

        # OptionParserのインスタンスを作成
        opt = OptionParser.new

        # 各オプション(.parse!時実行)
        # デバッグ用
        opt.on('-d', '--debug') {@logger.level = Logger::DEBUG}

        # オプションを切り取る
        opt.parse!(ARGV)

        # デバッグ状態の確認
        @logger.debug('DEBUG MODE')

        # 引数があるか確認
        if ARGV.size != 1
            @logger.fatal("引数が正しくありません")
            exit
        end

        @logger.debug("tmp: #{Keywords.keys.map{|key|Regexp.escape(key)}.join('|')}")

        formula = ARGV[0]

        begin
            calc(formula)
        rescue => e
            @logger.fatal(e.message)
            exit
        end

    end

    def calc(formula)
        # スキャナー作成
        @scanner = StringScanner.new(formula)

        # 字句解析実行
        tokens = _parse()

        # 意味解析実行
        printf("%s = %g\n", formula, _evaluate(tokens))
    end

    private def _get_token()
        # ここで、トークンの種類を判別する
        if @scanner.scan(/[\d.]+/)
            @logger.debug("matched_num: #{@scanner.matched}")
            return @scanner.matched.to_f
        elsif @scanner.scan(/(?:#{Keywords.keys.map{|key|Regexp.escape(key)}.join('|')})/)
            @logger.debug("matched_key: #{@scanner.matched}")
            return Keywords[@scanner.matched]
        else
            @logger.debug("matched: nil")
            return nil
        end
    end

    private def _unget_token(token)
        @logger.debug("unget: #{token}")
        @logger.debug("scanner_before: #{@scanner.inspect}")
        @scanner.unscan if !token.nil?
        @logger.debug("scanner_after: #{@scanner.inspect}")
    end

    # 抽象構文
    private def _parse()
        exp = _expression()
        @logger.debug("parse_result: #{exp}")
        return exp
    end

    # 式
    private def _expression()
        result = _term()
        token = _get_token()

        while token == :add || token == :sub
            result = [token, result, _term()]
            token = _get_token()
        end
        _unget_token(token)
        @logger.debug("expression_result: #{result}")
        return result
    end

    # 項と因子を分けているのは、演算子の優先順位を実装するため

    # 項
    private def _term()
        result = _factor()
        token = _get_token()

        while token == :mul || token == :div
            result = [token, result, _factor()]
            token = _get_token()
        end
        _unget_token(token)
        @logger.debug("term_result: #{result}")
        return result
    end

    # 因子
    private def _factor()
        token = _get_token()
        if token == :left_parn
            result = _expression()
            token = _get_token()
            if token != :right_parn
                raise(Exception, "')'がありません")
            end
            @logger.debug("factor_result: #{result}")
            return result
        elsif token.is_a?(Numeric)
            @logger.debug("factor_result(num): #{token}")
            return token
        else
            raise(Exception, "数値または'('がありません")
        end
    end

    # 意味解析
    private def _evaluate(exp)
        if exp.instance_of?(Array)
            case exp[0]
            when :add
                return _evaluate(exp[1]) + _evaluate(exp[2])
            when :sub
                return _evaluate(exp[1]) - _evaluate(exp[2])
            when :mul
                return _evaluate(exp[1]) * _evaluate(exp[2])
            when :div
                return _evaluate(exp[1]) / _evaluate(exp[2])
            end
        else
            return exp
        end
    end

end

CALC.new
