<?php

namespace App\Dto;

use JMS\Serializer\Serializer;
use LogicException;
use Symfony\Component\Validator\Constraint;
use Symfony\Component\Validator\Constraints\GroupSequence;
use Symfony\Component\Validator\Validator\ValidatorInterface;

class DtoFactory
{
    public function __construct(
        protected Serializer $serializer,
        protected ValidatorInterface $validator,
    ) {}

    /**
     * @param   class-string<Dto>  $className
     * @param   array|string       $data
     *
     * @return Dto
     *
     * @throws \LogicException
     *
     * @template Dto
     */
    public function create(string $className, array|string $data): DtoInterface
    {
        if (!is_subclass_of($className, DtoInterface::class)) {
            throw new LogicException(
                sprintf(
                    'Class %s should be the instance of %s', $className,
                    DtoInterface::class
                )
            );
        }

        if (is_array($data)) {
            $data = $this->serializer->serialize($data, 'json');
        }

        $dto = $this->serializer->deserialize($data, $className, 'json');
        $dto->setSerializer($this->serializer);

        return $dto;
    }

    /**
     * @param   Constraint|array|null            $constraints
     * @param   string|GroupSequence|array|null  $groups
     *
     */
    public function validate(
        DtoInterface $dto, Constraint|array|null $constraints = null,
        string|GroupSequence|array $groups = null
    ): array {
        $errors = [];

        $violations = [
            ...$this->validator->validate($dto, $constraints, $groups),
            ...$this->validator->validate(
                $dto->toArray(), $dto::getParamsConstraints(), $groups
            ),
        ];
        foreach ($violations as $violation) {
            $errors[] = sprintf(
                '"%s" - %s', $violation->getPropertyPath(),
                $violation->getMessage()
            );
        }

        return $errors;
    }

    /**
     * @param DtoInterface[] $dtoArray
     */
    public function validateDtoArray(array $dtoArray): array {
        $errors = [];

        foreach ($dtoArray as $dto) {
            $errors = [...$errors, ...$this->validate($dto)];
        }

        return $errors;
    }
}